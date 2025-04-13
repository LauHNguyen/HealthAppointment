import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../service/appointment_service.dart';

class AppointmentFilter extends StatefulWidget {
  final AppointmentService appointmentService;
  final String role;

  const AppointmentFilter({
    Key? key,
    required this.appointmentService,
    required this.role,
  }) : super(key: key);

  @override
  _AppointmentFilterState createState() => _AppointmentFilterState();
}

class _AppointmentFilterState extends State<AppointmentFilter> {
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'admin') {
      _loadAppointments();
    }
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      print(
          'Loading appointments for month: $_selectedMonth, year: $_selectedYear');
      final appointments =
          await widget.appointmentService.getAppointmentsByMonth(
        _selectedMonth,
        _selectedYear,
      );
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
      print('Loaded ${appointments.length} appointments');
      // In ra thông tin chi tiết của cuộc hẹn đầu tiên để debug
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

  @override
  Widget build(BuildContext context) {
    if (widget.role != 'admin') {
      return const Scaffold(
        body: Center(
          child: Text('Bạn không có quyền truy cập tính năng này'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lọc lịch hẹn theo tháng'),
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
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tháng',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      DropdownButton<int>(
                        value: _selectedMonth,
                        items: List.generate(12, (index) => index + 1)
                            .map((month) => DropdownMenuItem(
                                  value: month,
                                  child: Text('Tháng $month'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedMonth = value!);
                          _loadAppointments();
                        },
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Năm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      DropdownButton<int>(
                        value: _selectedYear,
                        items: List.generate(
                                10, (index) => DateTime.now().year - 5 + index)
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('Năm $year'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedYear = value!);
                          _loadAppointments();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_appointments.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Không có cuộc hẹn nào trong tháng này',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bệnh nhân: ${appointment.userName ?? 'Chưa có thông tin'}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.medical_services, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bác sĩ: ${appointment.doctorName ?? 'Chưa có thông tin'}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      if (appointment
                                              .doctorInfo?['specialty'] !=
                                          null)
                                        Text(
                                          'Chuyên khoa: ${appointment.doctorInfo!['specialty']}',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.local_hospital, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bệnh viện: ${appointment.hospitalName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Ngày: ${appointment.appointmentDate}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Giờ: ${appointment.appointmentTime}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
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
