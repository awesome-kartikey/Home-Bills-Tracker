import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';

class GenerateBillScreen extends StatefulWidget {
  final Tenant tenant;

  const GenerateBillScreen({super.key, required this.tenant});

  @override
  State<GenerateBillScreen> createState() => _GenerateBillScreenState();
}

class _GenerateBillScreenState extends State<GenerateBillScreen> {
  final _readingController = TextEditingController();
  bool _rentIncluded = true;
  double _unitsUsed = 0;
  double _electricityCost = 0;
  double _totalAmount = 0;
  GlobalSettings? _settings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _readingController.addListener(_calculateBill);
  }

  Future<void> _loadSettings() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final service = FirestoreService(userId: appProvider.user!.uid);
    final settingsStream = service.getSettings();
    await for (final settings in settingsStream) {
      if (mounted) {
        setState(() {
          _settings = settings;
        });
        _calculateBill();
      }
      break; // Take first value
    }
  }

  void _calculateBill() {
    if (_settings == null) return;

    final currentReading = double.tryParse(_readingController.text) ?? 0;
    if (currentReading < widget.tenant.lastReading) {
      // Invalid reading (less than previous)
      setState(() {
        _unitsUsed = 0;
        _electricityCost = 0;
        _totalAmount = 0;
      });
      return;
    }

    final units = currentReading - widget.tenant.lastReading;
    final elecCost = units * _settings!.electricityRate;
    final rent = _rentIncluded ? widget.tenant.rent : 0;
    
    setState(() {
      _unitsUsed = units;
      _electricityCost = elecCost;
      _totalAmount = elecCost + rent;
    });
  }

  Future<void> _saveBill() async {
    if (_settings == null) return;
    final currentReading = double.tryParse(_readingController.text) ?? 0;
    if (currentReading < widget.tenant.lastReading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current reading cannot be less than previous reading')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final service = FirestoreService(userId: appProvider.user!.uid);

      final bill = Bill(
        id: '',
        tenantId: widget.tenant.id,
        tenantName: widget.tenant.name,
        rentIncluded: _rentIncluded,
        lastReading: widget.tenant.lastReading,
        lastReadingDate: widget.tenant.lastReadingDate,
        latestReading: currentReading,
        latestReadingDate: Timestamp.now(),
        unitsUsed: _unitsUsed,
        rate: _settings!.electricityRate,
        electricityAmount: _electricityCost,
        rentAmount: _rentIncluded ? widget.tenant.rent : 0,
        totalAmount: _totalAmount,
        createdAt: Timestamp.now(),
      );

      await service.addBill(bill);

      // Update tenant's last reading
      final updatedTenant = Tenant(
        id: widget.tenant.id,
        name: widget.tenant.name,
        rent: widget.tenant.rent,
        lastReading: currentReading,
        lastReadingDate: Timestamp.now(),
        createdAt: widget.tenant.createdAt,
      );
      await service.updateTenant(updatedTenant);

      if (mounted) {
        Navigator.pop(context); // Go back to tenants list
        // Optionally navigate to history or show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill generated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill for ${widget.tenant.name}'),
      ),
      body: _settings == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Previous Reading:'),
                              Text(
                                '${widget.tenant.lastReading}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Rate per Unit:'),
                              Text(
                                '₹${_settings!.electricityRate}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _readingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Current Meter Reading',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Include Rent'),
                    subtitle: Text('₹${widget.tenant.rent}'),
                    value: _rentIncluded,
                    onChanged: (value) {
                      setState(() {
                        _rentIncluded = value;
                        _calculateBill();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSummaryRow('Units Used', '${_unitsUsed.toStringAsFixed(1)} units'),
                          const Divider(),
                          _buildSummaryRow('Electricity Cost', '₹${_electricityCost.toStringAsFixed(2)}'),
                          if (_rentIncluded) ...[
                            const SizedBox(height: 8),
                            _buildSummaryRow('Rent', '₹${widget.tenant.rent.toStringAsFixed(0)}'),
                          ],
                          const Divider(thickness: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${_totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveBill,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Generate & Save Bill'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
