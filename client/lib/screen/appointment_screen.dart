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
    getBookedList();
  }

  String? username;
  final SecureStorageService storage = SecureStorageService();
  DateTime selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime;
  String? selectedSlot;
  late List<String> bookedTime;
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
      await getBookedList();
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

                    // Kiểm tra ngày được chọn có phải hôm nay không
                    final isToday = selectedDate.year == today.year &&
                        selectedDate.month == today.month &&
                        selectedDate.day == today.day;

                    // Lấy giờ hiện tại
                    final now = TimeOfDay.now();
                    final nowDateTime = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      now.hour,
                      now.minute,
                    );

                    // Chuyển slot thành DateTime
                    final slotStartDateTime = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      slot['start']!.hour,
                      slot['start']!.minute,
                    );

                    // Chỉ kiểm tra giờ nếu ngày được chọn là hôm nay
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
                              }, // Vô hiệu hóa nếu không khả dụng
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
        Uri.parse('${dotenv.env['LOCALHOST']}/user/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // final user = data.firstWhere(
        //   (user) => user['username'].toString() == username.toString(),
        //   orElse: () => null,
        // );
        if (data != null) {
          setState(() {
            username = data['name'] ?? '';
          });
        } else {
          print('User not found in the response data');
        }
      } else {
        print('Fetched user ID does not match token ID');
        return null;
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
          bool doctorMatch = appointment['doctor']['_id'] == widget.doctorId;

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
      } else
        throw Exception('Failed to fetch appointments');
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
              colors: [Colors.teal, Colors.tealAccent], // Các màu gradient
              begin: Alignment.topLeft, // Hướng gradient bắt đầu
              end: Alignment.bottomRight, // Hướng gradient kết thúc
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin người dùng, bác sĩ và bệnh viện
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
                      "Bệnh Nhân: $username",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            // Chọn ngày hẹn
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
                          ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                          : "Chọn ngày",
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_today, color: Colors.blueAccent),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Chọn giờ hẹn
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
            // Nút xác nhận
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
