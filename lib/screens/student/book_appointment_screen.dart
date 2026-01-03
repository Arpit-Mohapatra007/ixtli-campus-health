import 'package:campus_health/utils/app_exception.dart' show AppException;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; 
import '../../providers/user_provider.dart';

class BookAppointmentScreen extends HookConsumerWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final reasonController = useTextEditingController();
    final selectedDate = useState<DateTime?>(null);
    final selectedTime = useState<TimeOfDay?>(null);
    final isLoading = useState(false);

    Future<void> pickDate() async {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 7)),
      );
      if (date != null) selectedDate.value = date;
    }

    Future<void> pickTime() async {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) selectedTime.value = time;
    }

    Future<void> submitBooking() async {
      if (selectedDate.value == null || selectedTime.value == null || reasonController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
        return;
      }

      isLoading.value = true;
      try {
        final userProfile = ref.read(currentUserProfileProvider).value;
        if (userProfile == null) throw AppException("User not found");

        final DateTime fullDateTime = DateTime(
          selectedDate.value!.year,
          selectedDate.value!.month,
          selectedDate.value!.day,
          selectedTime.value!.hour,
          selectedTime.value!.minute,
        );

        await FirebaseFirestore.instance.collection('appointments').add({
          'studentId': userProfile.uid,
          'studentName': userProfile.name,
          'doctorName': 'Triage Doctor',
          'date': Timestamp.fromDate(fullDateTime),
          'reason': reasonController.text.trim(),
          'status': 'pending',
          'hostel': userProfile.hostel, 
          'roomNumber': userProfile.roomNumber,
          'created_at': FieldValue.serverTimestamp(),
          'token_number': -1, 
        });

        if (context.mounted) {
          context.pop(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment Requested Successfully!"), backgroundColor: Colors.green)
          );
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason for visit (e.g., High Fever)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            
            ListTile(
              title: Text(selectedDate.value == null 
                  ? "Select Date" 
                  : DateFormat('yyyy-MM-dd').format(selectedDate.value!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickDate,
              tileColor: Colors.grey[800], 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 10),

            ListTile(
              title: Text(selectedTime.value == null 
                  ? "Select Time" 
                  : selectedTime.value!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: pickTime,
               tileColor: Colors.grey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 30),

            isLoading.value 
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: submitBooking,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text("Confirm Booking", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
          ],
        ),
      ),
    );
  }
}