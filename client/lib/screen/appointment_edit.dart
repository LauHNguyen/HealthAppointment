import 'dart:convert';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class EditAppointment extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final String? doctorId;
  final String? doctorName;
  final String? hospitalName;
  final String? workingHoursStart;
  final String? workingHoursEnd;
  final List<String>? workingDays;

  const EditAppointment({
    Key? key,
    required this.appointment,
    this.doctorId,
    this.doctorName,
    this.hospitalName,
    this.workingHoursStart,
    this.workingHoursEnd,
    this.workingDays,
  }) : super(key: key);

  @override
  State<EditAppointment> createState() => _EditAppointmentState();
}

class _EditAppointmentState extends State<EditAppointment> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late List<String> bookedTime;
  final SecureStorageService storage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    String time = widget.appointment['appointmentTime'] ?? '';
    final parts = time.split(' - ');
    String start = parts.isNotEmpty ? parts[0] : '';
    String end = parts.length > 1 ? parts[1] : '';
    _selectedDate =
        DateTime.tryParse(widget.appointment['appointmentDate'] ?? '') ??
            DateTime.now();
    _startTime = _parseTimeOfDay(start);
    _endTime = _parseTimeOfDay(end);
    getBookedList();
  }

  List<int> getValidWeekdaysFromString() {
    Map<String, int> weekdays = {
      "Monday": 1,
      "Tuesday": 2,
      "Wednesday": 3,
      "Thursday": 4,
      "Friday": 5,
      "Saturday": 6,
      "Sunday": 7
    };
    return widget.workingDays?.map((day) => weekdays[day]!).toList() ?? [];
  }

  DateTime _getNextValidDate(DateTime startDate, List<int> validWeekdays) {
    DateTime currentDate = startDate;
    while (!validWeekdays.contains(currentDate.weekday)) {
      currentDate = currentDate.add(Duration(days: 1));
    }
    return currentDate;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 00,
        minute: int.tryParse(parts[1]) ?? 00,
      );
    }
    return TimeOfDay(hour: 0, minute: 00);
  }

  bool _isWithinBreak(TimeOfDay time) {
    return (time.hour == 11 && time.minute >= 30) || (time.hour == 12);
  }

  List<Map<String, TimeOfDay>> _generateTimeSlots() {
    final start = widget.workingHoursStart != null
        ? _parseTime(widget.workingHoursStart!)
        : TimeOfDay.now();
    final end = widget.workingHoursEnd != null
        ? _parseTime(widget.workingHoursEnd!)
        : TimeOfDay(hour: 23, minute: 59);
    final List<Map<String, TimeOfDay>> slots = [];

    TimeOfDay current = start;
    while (current.hour < end.hour ||
        (current.hour == end.hour && current.minute < end.minute)) {
      final nextMinute = current.minute + 30;
      final nextHour = current.hour + (nextMinute >= 60 ? 1 : 0);
      final next = TimeOfDay(
        hour: nextHour,
        minute: nextMinute % 60,
      );
      if (!_isWithinBreak(current)) {
        if (next.hour < end.hour ||
            (next.hour == end.hour && next.minute <= end.minute)) {
          slots.add({'start': current, 'end': next});
        }
      }
      current = next;
    }
    return slots;
  }

  bool isBooked(TimeOfDay start, TimeOfDay end, List<String> bookedTime) {
    String formattedSlot =
        '${_formatTimeOfDay(start)} - ${_formatTimeOfDay(end)}';
    return bookedTime.contains(formattedSlot);
  }

  Future<void> getBookedList() async {
    try {
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }
      final response = await http.get(
        Uri.parse('${dotenv.env['LOCALHOST']}/appointment'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> appointments = jsonDecode(response.body);

        bookedTime = appointments.where((appointment) {
          bool doctorMatch = appointment['doctor']['_id'] == widget.doctorId;

          DateTime appointmentDate =
              DateTime.parse(appointment['appointmentDate']);
          String formattedAppointmentDate =
              DateFormat('yyyy-MM-dd').format(appointmentDate);
          String formattedSelectedDate =
              DateFormat('yyyy-MM-dd').format(_selectedDate!);
          bool dateMatch = formattedAppointmentDate == formattedSelectedDate;

          return doctorMatch && dateMatch;
        }).map((appointment) {
          return appointment['appointmentTime'] as String;
        }).toList();

        setState(() {}); // Trigger a rebuild
      } else {
        throw Exception('Failed to fetch appointments');
      }
    } catch (e) {
      print('Error when get booked list: $e');
    }
  }

  Future<void> _pickDate() async {
    List<int> validWeekdays = getValidWeekdaysFromString();
    DateTime validInitialDate =
        _getNextValidDate(_selectedDate ?? DateTime.now(), validWeekdays);

    final date = await showDatePicker(
      context: context,
      initialDate: validInitialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        return validWeekdays.contains(day.weekday);
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      await getBookedList();
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showCustomTimePicker(BuildContext context) async {
    final slots = _generateTimeSlots();
    await showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn khoảng thời gian',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final today = DateTime.now();
                    final isToday = _selectedDate!.year == today.year &&
                        _selectedDate!.month == today.month &&
                        _selectedDate!.day == today.day;
                    final now = TimeOfDay.now();
                    final nowDateTime = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      now.hour,
                      now.minute,
                    );
                    final slotStartDateTime = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      slot['start']!.hour,
                      slot['start']!.minute,
                    );
                    final bool isPast =
                        isToday && slotStartDateTime.isBefore(nowDateTime);
                    final bool booked =
                        isBooked(slot['start']!, slot['end']!, bookedTime);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: booked || isPast ? Colors.red : Colors.green,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: booked || isPast
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                      ),
                      child: ListTile(
                        title: Text(
                          '${_formatTimeOfDay(slot['start']!)} - ${_formatTimeOfDay(slot['end']!)}',
                          style: TextStyle(
                            color: booked || isPast ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: booked || isPast
                            ? null
                            : () {
                                setState(() {
                                  _startTime = slot['start'];
                                  _endTime = slot['end'];
                                });
                                Navigator.pop(context);
                              },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hãy chọn thời gian hẹn!')),
      );
      return;
    }
    try {
      final response = await http.patch(
        Uri.parse(
            '${dotenv.env['LOCALHOST']}/appointment/${widget.appointment['_id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'appointmentDate': _selectedDate!.toIso8601String(),
          'appointmentTime':
              '${_formatTimeOfDay(_startTime!)} - ${_formatTimeOfDay(_endTime!)}',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lịch hẹn đã được cập nhật thành công.')),
        );
        Navigator.pop(context);
        Navigator.pushNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Cập nhật thất bại: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa lịch hẹn',
            style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent], // Các màu gradient
              begin: Alignment.topLeft, // Hướng gradient bắt đầu
              end: Alignment.bottomRight, // Hướng gradient kết thúc
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Ngày'),
              subtitle: Text(
                  '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDate,
              ),
            ),
            ListTile(
              title: const Text('Giờ hẹn'),
              subtitle: Text(_startTime != null && _endTime != null
                  ? '${_formatTimeOfDay(_startTime!)}- ${_formatTimeOfDay(_endTime!)}'
                  : 'Chưa chọn'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _showCustomTimePicker(context),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}
