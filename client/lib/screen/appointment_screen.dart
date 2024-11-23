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
    List<String>? workingDays, // Cho phép null ở đây
  }) : workingDays = workingDays ?? const [];

  @override
  _AppointmentState createState() => _AppointmentState();
}

class _AppointmentState extends State<Appointment> {
  @override
  void initState() {
    super.initState();
    getUserName();
  }

  String? userName;
  final SecureStorageService storage = SecureStorageService();
  DateTime selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  TimeOfDay? selectedTime;

  // Chuyển đổi chuỗi thời gian dạng "HH:mm" thành TimeOfDay
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
      return TimeOfDay(hour: 9, minute: 0); // Giá trị mặc định nếu lỗi
    }
  }

  Future<void> pickDate(BuildContext context) async {
    // Chuyển mảng workingDays từ String thành weekday
    List<int> validWeekdays = getValidWeekdaysFromString();

    // Đảm bảo initialDate nằm trong validWeekdays
    DateTime validInitialDate =
        _getNextValidDate(DateTime.now(), validWeekdays);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: validInitialDate, // Dùng ngày hợp lệ
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      selectableDayPredicate: (DateTime day) {
        // Chỉ cho phép các ngày có trong validWeekdays
        return validWeekdays.contains(day.weekday);
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  DateTime _getNextValidDate(DateTime startDate, List<int> validWeekdays) {
    DateTime currentDate = startDate;

    // Tìm ngày hợp lệ tiếp theo
    while (!validWeekdays.contains(currentDate.weekday)) {
      currentDate =
          currentDate.add(Duration(days: 1)); // Chuyển sang ngày tiếp theo
    }

    return currentDate;
  }

  List<int> getValidWeekdaysFromString() {
    // Đoạn mã này chuyển đổi từ tên ngày sang weekday
    Map<String, int> weekdays = {
      "Monday": 1,
      "Tuesday": 2,
      "Wednesday": 3,
      "Thursday": 4,
      "Friday": 5,
      "Saturday": 6,
      "Sunday": 7
    };

    // Mảng workingDays của bạn, bạn cần thay thế từ phía backend hoặc truyền vào
    List<String> workDays = widget.workingDays;

    // Chuyển đổi từ workingDays sang weekday
    List<int> validWeekdays = [];
    for (String day in workDays) {
      if (weekdays.containsKey(day)) {
        validWeekdays.add(weekdays[day]!);
      }
    }

    return validWeekdays;
  }

  List<TimeOfDay> generateAvailableTimeSlots() {
    List<TimeOfDay> timeSlots = [];
    TimeOfDay start = parseTime(widget.workingHoursStart); // "6:00"
    TimeOfDay end = parseTime(widget.workingHoursEnd); // "18:00"

    // Vòng lặp để tạo ra các khung giờ cách nhau 15 phút
    while (start.hour < end.hour ||
        (start.hour == end.hour && start.minute < end.minute)) {
      // Loại bỏ giờ nghỉ trưa từ 11h30 - 13h
      if (!(start.hour == 11 && start.minute >= 30) &&
          !(start.hour == 12) &&
          !(start.hour == 13 && start.minute == 0)) {
        timeSlots.add(start);
      }

      // Tăng thời gian lên 15 phút
      final nextMinute = (start.minute + 15) % 60;
      final nextHour = start.minute + 15 >= 60 ? start.hour + 1 : start.hour;
      start = TimeOfDay(hour: nextHour, minute: nextMinute);
    }
    return timeSlots;
  }

  Future<void> confirmAppointment() async {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hãy chọn thời gian hẹn!')),
      );
      return;
    }
    final appointmentDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final appointmentData = {
      "user": widget.userId,
      "doctor": widget.doctorId,
      "hospitalName": widget.hospitalName,
      "appointmentDate": appointmentDate,
      "appointmentTime": "${selectedTime!.hour}:${selectedTime!.minute}",
      "createdAt": DateTime.now().toIso8601String(),
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
        throw Exception('Failed to create appointment');
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
        // print('user---:${response.body}');
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

  @override
  Widget build(BuildContext context) {
    List<TimeOfDay> timeSlots = generateAvailableTimeSlots();

    return Scaffold(
      appBar: AppBar(title: Text("Đặt lịch hẹn")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Người dùng: $userName", textAlign: TextAlign.center),
            Text("Bác sĩ: ${widget.doctorName}", textAlign: TextAlign.center),
            Text("Bệnh viện: ${widget.hospitalName}",
                textAlign: TextAlign.center),
            Text("Ngày làm: ${widget.workingDays}",
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => pickDate(context),
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Ngày hẹn: ${selectedDate.toLocal()}".split(' ')[0],
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_today, color: Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text("Chọn giờ hẹn:", style: TextStyle(fontSize: 16)),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: timeSlots.map((time) {
                return ChoiceChip(
                  label: Text(time.format(context)),
                  selected: selectedTime == time,
                  onSelected: (selected) {
                    setState(() {
                      selectedTime = selected ? time : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: confirmAppointment,
              child: Text(
                  "Xác nhận đặt lịch  thời gian :$selectedTime  & $selectedDate"),
            ),
          ],
        ),
      ),
    );
  }
}
