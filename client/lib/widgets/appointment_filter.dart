import 'dart:convert';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/appointment.dart';
import '../service/appointment_service.dart';
import 'package:http/http.dart' as http;

class AppointmentFilter extends StatefulWidget {
  final AppointmentService appointmentService;

  const AppointmentFilter({
    Key? key,
    required this.appointmentService,
  }) : super(key: key);

  @override
  _AppointmentFilterState createState() => _AppointmentFilterState();
}

class _AppointmentFilterState extends State<AppointmentFilter> {
  final SecureStorageService storage = SecureStorageService();
  List<Appointment> _appointments = [];
  List<String> _doctors = [];
  bool _isLoading = false;
  int? _selectedMonth = DateTime.now().month;
  int? _selectedYear = DateTime.now().year;
  int? _selectedDate = DateTime.now().day;
  String? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _fetchDoctors();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final appointments = await widget.appointmentService.filterAppointments(
        _selectedMonth,
        _selectedYear,
        _selectedDate,
        _selectedDoctor,
      );
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }

      if (appointments.isNotEmpty) {
        final firstAppointment = appointments.first;
        print('First appointment details:');
        print('Doctor info: ${firstAppointment.doctorInfo}');
        print('User info: ${firstAppointment.userInfo}');
        print('Doctor name: ${firstAppointment.doctorName}');
        print('User name: ${firstAppointment.userName}');
      }
    } catch (e) {
      print('Error loading appointments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách cuộc hẹn: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchDoctors() async {
    try {
      await _loadAppointments(); // Gọi để có _appointments
      if (mounted) {
        setState(() {
          _doctors = _appointments
              .map((a) => a.doctorName)
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList();
        });
        print('Doctors list from appointments: $_doctors');
      }
    } catch (e) {
      print('Error fetching doctors from appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách bác sĩ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getDaysInMonth(int? month, int? year) {
    if (month == null || year == null) {
      return 31; // Giá trị mặc định khi không xác định tháng/năm
    }
    if (month == 2) {
      bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    return [4, 6, 9, 11].contains(month) ? 30 : 31;
  }

  @override
  Widget build(BuildContext context) {
    final maxDays = _getDaysInMonth(_selectedMonth, _selectedYear);
    // Đảm bảo _selectedDate hợp lệ
    if (_selectedDate != null &&
        _selectedMonth != null &&
        _selectedYear != null) {
      if (_selectedDate! > maxDays) {
        _selectedDate = null; // Reset về "Tất cả" nếu ngày không hợp lệ
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lọc Lịch Hẹn'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            // Filter Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month, Year, Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Month Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tháng',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          DropdownButton<int?>(
                            value: _selectedMonth,
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Tất cả'),
                              ),
                              ...List.generate(12, (index) => index + 1)
                                  .map((month) => DropdownMenuItem<int?>(
                                        value: month,
                                        child: Text('Tháng $month'),
                                      ))
                                  .toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedMonth = value;
                                if (_selectedMonth == null ||
                                    _selectedYear == null) {
                                  _selectedDate =
                                      null; // Reset ngày khi chọn "Tất cả"
                                } else {
                                  final maxDays = _getDaysInMonth(
                                      _selectedMonth, _selectedYear);
                                  if (_selectedDate == null ||
                                      _selectedDate! > maxDays) {
                                    _selectedDate =
                                        1; // Reset ngày nếu không hợp lệ
                                  }
                                }
                              });
                              _loadAppointments();
                              _fetchDoctors();
                            },
                            underline: Container(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      // Year Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Năm',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          DropdownButton<int?>(
                            value: _selectedYear,
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Tất cả'),
                              ),
                              ...List.generate(
                                10,
                                (index) => DateTime.now().year - 5 + index,
                              )
                                  .map((year) => DropdownMenuItem<int?>(
                                        value: year,
                                        child: Text('Năm $year'),
                                      ))
                                  .toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value;
                                if (_selectedYear == null ||
                                    _selectedMonth == null) {
                                  _selectedDate =
                                      null; // Reset ngày khi chọn "Tất cả"
                                } else {
                                  final maxDays = _getDaysInMonth(
                                      _selectedMonth, _selectedYear);
                                  if (_selectedDate == null ||
                                      _selectedDate! > maxDays) {
                                    _selectedDate =
                                        1; // Reset ngày nếu không hợp lệ
                                  }
                                }
                              });
                              _loadAppointments();
                              _fetchDoctors();
                            },
                            underline: Container(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      // Date Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ngày',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          DropdownButton<int?>(
                            value: _selectedDate,
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Tất cả'),
                              ),
                              if (_selectedMonth != null &&
                                  _selectedYear != null)
                                ...List.generate(
                                  maxDays,
                                  (index) => index + 1,
                                )
                                    .map((date) => DropdownMenuItem<int?>(
                                          value: date,
                                          child: Text('Ngày $date'),
                                        ))
                                    .toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDate = value;
                              });
                              _loadAppointments();
                              _fetchDoctors();
                            },
                            underline: Container(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Doctor Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bác sĩ',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      DropdownButton<String>(
                        value: _selectedDoctor,
                        hint: const Text('Chọn bác sĩ'),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tất cả'),
                          ),
                          ..._doctors.map((name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDoctor = value);
                          _loadAppointments();
                        },
                        underline: Container(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Appointment List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    )
                  : _appointments.isEmpty
                      ? const Center(
                          child: Text(
                            'Không có lịch hẹn nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _appointments[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.teal.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Patient
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            size: 20,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Bệnh nhân: ${appointment.userName}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Doctor
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.medical_services,
                                            size: 20,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Bác sĩ: ${appointment.doctorName}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (appointment.doctorInfo?[
                                                        'specialty'] !=
                                                    null)
                                                  Text(
                                                    'Chuyên khoa: ${appointment.doctorInfo!['specialty']}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Hospital
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.local_hospital,
                                            size: 20,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Bệnh viện: ${appointment.hospitalName}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Date and Time
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 20,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Ngày: ${appointment.appointmentDate}',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(
                                            Icons.access_time,
                                            size: 20,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Giờ: ${appointment.appointmentTime}',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
