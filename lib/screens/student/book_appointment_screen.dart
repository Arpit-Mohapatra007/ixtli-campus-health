import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../../providers/appointment_provider.dart' show appointmentServiceProvider;
import '../../providers/content_provider.dart' show specialistScheduleProvider;
import '../../providers/user_provider.dart';

class BookAppointmentScreen extends ConsumerWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(specialistScheduleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (scheduleList) {
          return _CalendarBody(scheduleList: scheduleList);
        }
      ),
    );
  }
}

class _CalendarBody extends StatefulHookConsumerWidget {
  final List<Map<String, dynamic>> scheduleList;
  const _CalendarBody({required this.scheduleList});

  @override
  ConsumerState<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends ConsumerState<_CalendarBody> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<String> _getEventsForDay(DateTime day) {
    final cleanDay = DateTime(day.year, day.month, day.day);
    
    final events = widget.scheduleList.where((item) {
      final itemDate = item['date'] as DateTime;
      final cleanItemDate = DateTime(itemDate.year, itemDate.month, itemDate.day);
      return cleanItemDate == cleanDay;
    }).map((e) => e['specialist'] as String).toList();
    
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final reasonController = useTextEditingController();
    final isLoading = useState(false);
    final user = ref.watch(currentUserProfileProvider).value;
    final now = DateTime.now();
    Future<void> handleBooking() async {
      if (_selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a date")));
        return;
      }
      if (reasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a reason for visit")));
        return;
      }
      if (user == null) return;

      isLoading.value = true;
      try {
        await ref.read(appointmentServiceProvider).requestAppointment(
          studentId: user.uid,
          studentName: user.name,
          hostel: user.hostel,
          reason: reasonController.text.trim(),
          date: _selectedDay!,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment Requested Successfully!")));
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      } finally {
        isLoading.value = false;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar(
            firstDay: now,
            lastDay: DateTime(now.year, now.month + 1, 0),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
          const SizedBox(height: 20),
          
          if (_selectedDay != null) ...[
               Container(
                 padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                 decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                 child: Text("Selected: ${_selectedDay.toString().split(' ')[0]}", style: const TextStyle(fontWeight: FontWeight.bold)),
               ),
               const SizedBox(height: 10),
               
               if (_getEventsForDay(_selectedDay!).isNotEmpty)
                 Container(
                   padding: const EdgeInsets.all(12),
                   margin: const EdgeInsets.symmetric(horizontal: 20),
                   decoration: BoxDecoration(
                     color: Colors.pink[50], 
                     borderRadius: BorderRadius.circular(10), 
                     border: Border.all(color: Colors.pink)
                   ),
                   child: Row(
                     children: [
                       const Icon(Icons.star, color: Colors.pink),
                       const SizedBox(width: 10),
                       Text("Visiting: ${_getEventsForDay(_selectedDay!).join(', ')}", style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                     ],
                   ),
                 )
               else
                 const Padding(
                   padding: EdgeInsets.all(8.0),
                   child: Text("Regular OPD Available", style: TextStyle(color: Colors.grey)),
                 ),
          ],
      
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Reason for Visit / Symptoms",
                hintText: "e.g. Fever, Headache, Stomach pain",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note)
              ),
            ),
          ),
      
          const SizedBox(height: 30),
      
          if (isLoading.value)
             const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: handleBooking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white
              ),
              child: const Text("Confirm Appointment"),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}