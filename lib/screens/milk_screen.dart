import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';

class MilkScreen extends StatefulWidget {
  const MilkScreen({super.key});

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> {
  DateTime _selectedDate = DateTime.now();

  void _showAddEntryDialog(BuildContext context, FirestoreService service, MilkDoc? milkDoc) {
    final qtyController = TextEditingController();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final existingQty = milkDoc?.days[dateStr]?.fold(0.0, (a, b) => a + b) ?? 0.0;
    
    // If editing, maybe show existing entries? For now, just add new entry.
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Milk for ${DateFormat('MMM d').format(_selectedDate)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (existingQty > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text('Total so far: $existingQty liters'),
              ),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity (liters)',
                hintText: 'e.g. 1.5',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text);
              if (qty == null) return;

              final currentList = milkDoc?.days[dateStr] ?? [];
              final newList = List<double>.from(currentList)..add(qty);

              await service.updateMilkDay(dateStr, newList);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final firestoreService = FirestoreService(userId: appProvider.user!.uid);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<MilkDoc?>(
              stream: firestoreService.getMilkDoc(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final milkDoc = snapshot.data;
                final days = milkDoc?.days ?? {};

                // Generate list of days for selected month
                final daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: daysInMonth,
                  itemBuilder: (context, index) {
                    final day = DateTime(_selectedDate.year, _selectedDate.month, daysInMonth - index);
                    final dateStr = DateFormat('yyyy-MM-dd').format(day);
                    final quantities = days[dateStr] ?? [];
                    final total = quantities.fold(0.0, (a, b) => a + b);
                    final isToday = DateUtils.isSameDay(day, DateTime.now());

                    return Card(
                      elevation: 0,
                      color: isToday ? Colors.blue[50] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isToday ? Colors.blue[200]! : Colors.grey[200]!),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          setState(() => _selectedDate = day);
                          _showAddEntryDialog(context, firestoreService, milkDoc);
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: total > 0 ? Colors.blue[100] : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: total > 0 ? Colors.blue[800] : Colors.grey[600],
                            ),
                          ),
                        ),
                        title: Text(
                          DateFormat('EEEE').format(day),
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: total > 0
                            ? Text(
                                '$total L',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              )
                            : const Icon(Icons.add, size: 20, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            // Ensure selected date is today or allow user to pick
            setState(() => _selectedDate = DateTime.now());
             // We need to fetch the doc again or pass it? 
             // The dialog needs the doc to show current total.
             // For simplicity, we trigger the dialog via the list item usually, 
             // but FAB can trigger for "Today".
             // We can't easily get the doc here without the stream data.
             // So let's just make the FAB scroll to today or pick date.
             _pickDate();
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.calendar_month),
      ),
    );
  }
}
