import 'dart:convert';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Appointment extends StatefulWidget {
  final String userId;
  final String doctorId;
  final String doctorName;
  final String hospitalName;
  final String workingHoursStart;
  final String workingHoursEnd;
  final List<String> workingDays;

  const Appointment({
    required this.userId,
    required this.doctorId,
    required this.doctorName,
    required this.hospitalName,
    required this.workingHoursStart,
    required this.workingHoursEnd,
    List<String>? workingDays,
  }) : workingDays = workingDays ?? const [];

  @override
  _AppointmentState createState() => _AppointmentState();
}

class _AppointmentState extends State<Appointment> {
  String? userName;
  final SecureStorageService storage = SecureStorageService();
  DateTime selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime;
  String? selectedSlot;
  List<String> bookedTime = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await getUserName();
      await getBookedList();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  TimeOfDay parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format for timeStr: $timeStr');
      }
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        throw FormatException('Time out of range: $timeStr');
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print("Error parsing time: $e");
      return TimeOfDay(hour: 9, minute: 0);
    }
  }

  Future<void> pickDate(BuildContext context) async {
    List<int> validWeekdays = getValidWeekdaysFromString();
    DateTime validInitialDate =
        _getNextValidDate(DateTime.now(), validWeekdays);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: validInitialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        return validWeekdays.contains(day.weekday);
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await getBookedList();
    }
  }

  DateTime _getNextValidDate(DateTime startDate, List<int> validWeekdays) {
    DateTime currentDate = startDate;
    while (!validWeekdays.contains(currentDate.weekday)) {
      currentDate = currentDate.add(Duration(days: 1));
    }
    return currentDate;
  }

  List<int> getValidWeekdaysFromString() {
    Map<String, int> weekdays = {
      // "Monday": 1,
      // "Tuesday": 2,
      // "Wednesday": 3,
      // "Thursday": 4,
      // "Friday": 5,
      // "Saturday": 6,
      // "Sunday": 7,
      "Thứ Hai": 1,
      "Thứ Ba": 2,
      "Thứ Tư": 3,
      "Thứ Năm": 4,
      "Thứ Sáu": 5,
      "Thứ Bảy": 6,
      "Chủ Nhật": 7
    };
    List<String> workDays = widget.workingDays;
    List<int> validWeekdays = [];
    for (String day in workDays) {
      if (weekdays.containsKey(day)) {
        validWeekdays.add(weekdays[day]!);
      }
    }
    return validWeekdays;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isWithinBreak(TimeOfDay time) {
    return (time.hour == 11 && time.minute >= 30) || (time.hour == 12);
  }

  List<Map<String, TimeOfDay>> _generateTimeSlots() {
    if (selectedDate == null) {
      throw Exception('Hãy chọn ngày khám trước khi tạo danh sách thời gian!');
    }
    final start = _parseTime(widget.workingHoursStart);
    final end = _parseTime(widget.workingHoursEnd);
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

  Future<void> _showCustomTimePicker(BuildContext context) async {
    if (isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đang tải dữ liệu, vui lòng chờ...')),
      );
      return;
    }
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
                    final isToday = selectedDate.year == today.year &&
                        selectedDate.month == today.month &&
                        selectedDate.day == today.day;
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
                    final DateFormat timeFormat = DateFormat.Hm();
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
                          '${timeFormat.format(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, slot['start']!.hour, slot['start']!.minute))} - '
                          '${timeFormat.format(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, slot['end']!.hour, slot['end']!.minute))}',
                          style: TextStyle(
                            color: booked || isPast ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: booked || isPast
                            ? null
                            : () {
                                setState(() {
                                  selectedTime = slot['start'];
                                  selectedEndTime = slot['end'];
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

  Future<void> confirmAppointment() async {
    if (selectedTime == null || selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hãy chọn thời gian hẹn!')),
      );
      return;
    }
    final appointmentData = {
      "user": widget.userId,
      "doctor": widget.doctorId,
      "hospitalName": widget.hospitalName,
      "appointmentDate": DateFormat('yyyy-MM-dd').format(selectedDate),
      "appointmentTime":
          "${DateFormat('HH:mm').format(DateTime(0, 0, 0, selectedTime!.hour, selectedTime!.minute))} - ${DateFormat('HH:mm').format(DateTime(0, 0, 0, selectedEndTime!.hour, selectedEndTime!.minute))}",
    };
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['LOCALHOST']}/appointment/create'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(appointmentData),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt lịch thành công!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception(
            'Failed to create appointment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error booking appointment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đặt lịch!')),
      );
    }
  }

  Future<void> getUserName() async {
    try {
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }
      final response = await http.get(
        Uri.parse('${dotenv.env['LOCALHOST']}/user/name'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['username'];
        });
      } else {
        throw Exception('Failed to get user name');
      }
    } catch (e) {
      print('Error when get user name: $e');
    }
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
          bool doctorMatch = appointment['doctor'] == widget.doctorId;
          DateTime appointmentDate =
              DateTime.parse(appointment['appointmentDate']);
          String formattedAppointmentDate =
              DateFormat('yyyy-MM-dd').format(appointmentDate);
          String formattedSelectedDate =
              DateFormat('yyyy-MM-dd').format(selectedDate);
          bool dateMatch = formattedAppointmentDate == formattedSelectedDate;
          return doctorMatch && dateMatch;
        }).map((appointment) {
          print('Matched appointment: ${appointment['appointmentTime']}');
          return appointment['appointmentTime'] as String;
        }).toList();
        print('Booked Times: $bookedTime');
      } else {
        throw Exception(
            'Failed to fetch appointments: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error when get booked list: $e');
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool isBooked(TimeOfDay start, TimeOfDay end, List<String> bookedTime) {
    String formattedSlot =
        '${_formatTimeOfDay(start)} - ${_formatTimeOfDay(end)}';
    return bookedTime.contains(formattedSlot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Đặt lịch hẹn",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    margin: EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bệnh Nhân: $userName",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Bác sĩ: ${widget.doctorName}",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Bệnh viện: ${widget.hospitalName}",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Ngày làm: ${widget.workingDays}",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Chọn ngày hẹn:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => pickDate(context),
                    child: Container(
                      padding: EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null
                                ? DateFormat('dd/MM/yyyy').format(selectedDate)
                                : "Chọn ngày",
                            style: TextStyle(fontSize: 16),
                          ),
                          Icon(Icons.calendar_today, color: Colors.blueAccent),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Chọn khoảng thời gian:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showCustomTimePicker(context),
                    child: Container(
                      padding: EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedTime != null && selectedEndTime != null
                                ? "${DateFormat('HH:mm').format(DateTime(0, 0, 0, selectedTime!.hour, selectedTime!.minute))} - ${DateFormat('HH:mm').format(DateTime(0, 0, 0, selectedEndTime!.hour, selectedEndTime!.minute))}"
                                : "Chọn thời gian",
                            style: TextStyle(fontSize: 16),
                          ),
                          Icon(Icons.access_time, color: Colors.blueAccent),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: confirmAppointment,
                      child: Text(
                        "Xác nhận đặt lịch",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
