import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/api_data_provider.dart';
import '../../providers/auth_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final Set<DateTime> _selectedDays = {};
  bool _isSubmitting = false;

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      // Toggle selection
      final normalizedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
      if (_selectedDays.contains(normalizedDay)) {
        _selectedDays.remove(normalizedDay);
      } else {
        _selectedDays.add(normalizedDay);
      }
    });
  }

  Future<void> _submitRequest(String type) async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<ApiDataProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profileData = provider.myProfile ?? auth.user ?? {};
      final employeeId = profileData['employeeId'];
      final employeeName = '${profileData['firstName'] ?? ''} ${profileData['lastName'] ?? ''}'.trim();

      if (employeeId == null) {
        throw Exception('User profile not fully loaded. Please wait.');
      }

      final List<String> formattedDates = _selectedDays.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();

      await provider.submitApproval({
        'type': 'ATTENDANCE',
        'employeeId': employeeId,
        'employeeName': employeeName.isNotEmpty ? employeeName : 'Executive',
        'details': {
          'dates': formattedDates,
          'markAs': type,
        }
      });

      if (mounted) {
        setState(() {
          _selectedDays.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request for $type sent for approval.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ApiDataProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final profileData = provider.myProfile ?? auth.user ?? {};
    final attendanceRecords = Map<String, dynamic>.from(profileData['attendanceRecords'] ?? {});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                  selectedDayPredicate: (day) {
                    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
                    return _selectedDays.contains(normalizedDay);
                  },
                  onDaySelected: _onDaySelected,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(day);
                      final record = attendanceRecords[dateStr];

                      Color? dotColor;
                      if (record == 'PRESENT') {
                        dotColor = Colors.green;
                      } else if (record == 'LEAVE') {
                        dotColor = Colors.redAccent;
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (dotColor != null)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
                    int presentDays = 0;
                    int absentDays = 0;

                    for (int i = 1; i <= daysInMonth; i++) {
                      final date = DateTime(_focusedDay.year, _focusedDay.month, i);
                      final dateStr = DateFormat('yyyy-MM-dd').format(date);
                      final record = attendanceRecords[dateStr];
                      
                      if (record?.toUpperCase() == 'PRESENT') {
                        presentDays++;
                      } else if (record?.toUpperCase() == 'LEAVE') {
                        absentDays++;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${DateFormat('MMMM yyyy').format(_focusedDay)} Summary',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn('Total Days', daysInMonth.toString(), Colors.blueGrey),
                                _buildStatColumn('Present', presentDays.toString(), Colors.green),
                                _buildStatColumn('Leave/Absent', absentDays.toString(), Colors.redAccent),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          const Text('Approved Present', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          const Text('Approved Leave', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _submitRequest('PRESENT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Request Present', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _submitRequest('LEAVE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.event_busy),
                          label: const Text('Request Leave', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
    );
  }
  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
      ],
    );
  }
}
