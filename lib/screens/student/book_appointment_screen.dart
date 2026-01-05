import 'package:campus_health/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../../providers/appointment_provider.dart' show appointmentServiceProvider;
import '../../providers/content_provider.dart' show specialistScheduleProvider;
import '../../providers/user_provider.dart';

class BookAppointmentScreen extends ConsumerWidget {
  final String? initialCategory;
  
  const BookAppointmentScreen({
    super.key, 
    this.initialCategory
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(specialistScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Appointment"), 
        backgroundColor: Colors.teal, 
        foregroundColor: Colors.white
      ),
      body: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (scheduleList) {
          return _CalendarBody(
            scheduleList: scheduleList,
            initialCategory: initialCategory,
          );
        }
      ),
    );
  }
}

class _CalendarBody extends StatefulHookConsumerWidget {
  final List<Map<String, dynamic>> scheduleList;
  final String? initialCategory;

  const _CalendarBody({
    required this.scheduleList, 
    this.initialCategory
  });

  @override
  ConsumerState<_CalendarBody> createState() => _CalendarBodyState();
}

class _CalendarBodyState extends ConsumerState<_CalendarBody> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late String _selectedCategory; 

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? AppConstants.generalPhysician;
  }

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

    List<String> specialists = [];
    if (_selectedDay != null) {
      specialists = _getEventsForDay(_selectedDay!);
    }

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
          category: _selectedCategory,
          bloodGroup: user.bloodGroup,
          dob: user.dob,
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
                if (!specialists.contains(_selectedCategory) && _selectedCategory != AppConstants.generalPhysician) {
                   _selectedCategory = AppConstants.generalPhysician;
                }
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
               const SizedBox(height: 15),
               if (specialists.isNotEmpty) ...[
                 Container(
                   padding: const EdgeInsets.all(16),
                   margin: const EdgeInsets.symmetric(horizontal: 20),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: Colors.grey.shade300),
                     boxShadow: [
                       BoxShadow(color: Colors.black, blurRadius: 10, offset: const Offset(0, 4))
                     ]
                   ),
                   child: Column(
                     children: [
                       const Text("Who do you want to consult?", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 15),
                       SizedBox(
                         width: double.infinity,
                         height: 50,
                         child: ElevatedButton.icon(
                           onPressed: () => setState(() => _selectedCategory = AppConstants.generalPhysician),
                           icon: Icon(Icons.medical_services_outlined, 
                             color: _selectedCategory == AppConstants.generalPhysician ? Colors.white : Colors.teal
                           ),
                           label: const Text("General Physician (OPD)"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: _selectedCategory == AppConstants.generalPhysician ? Colors.teal : Colors.grey[100],
                             foregroundColor: _selectedCategory == AppConstants.generalPhysician ? Colors.white : Colors.black87,
                             elevation: _selectedCategory == AppConstants.generalPhysician ? 4 : 0,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(12),
                               side: _selectedCategory == AppConstants.generalPhysician 
                                  ? BorderSide.none 
                                  : const BorderSide(color: Colors.teal, width: 1.5)
                             )
                           ),
                         ),
                       ),
                       
                       const SizedBox(height: 10),
                       const Text("OR", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 10),
                       ...specialists.map((spec) => SizedBox(
                         width: double.infinity,
                         height: 50,
                         child: ElevatedButton.icon(
                           onPressed: () => setState(() => _selectedCategory = spec),
                           icon: Icon(Icons.star_outline, 
                             color: _selectedCategory == spec ? Colors.white : Colors.pink
                           ),
                           label: Text("$spec (Specialist)"),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: _selectedCategory == spec ? Colors.pink : Colors.grey[100],
                             foregroundColor: _selectedCategory == spec ? Colors.white : Colors.black87,
                             elevation: _selectedCategory == spec ? 4 : 0,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(12),
                               side: _selectedCategory == spec
                                  ? BorderSide.none 
                                  : const BorderSide(color: Colors.pink, width: 1.5)
                             )
                           ),
                         ),
                       )),
                     ],
                   ),
                 )
               ] else ...[
                 Container(
                   padding: const EdgeInsets.all(12),
                   margin: const EdgeInsets.symmetric(horizontal: 20),
                   decoration: BoxDecoration(
                     color: Colors.teal[50], 
                     borderRadius: BorderRadius.circular(10), 
                     border: Border.all(color: Colors.teal)
                   ),
                   child: const Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.check_circle, color: Colors.teal),
                       SizedBox(width: 10),
                       Text("Regular OPD Available", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                     ],
                   ),
                 )
               ],
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
                backgroundColor: _selectedCategory == AppConstants.generalPhysician ? Colors.teal : Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
              child: Text("Confirm Appointment ($_selectedCategory)"),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}