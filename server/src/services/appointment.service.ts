import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Appointment, AppointmentDocument } from '../schema/appointment.schema';
import { Hospital, HospitalDocument } from '../schema/hospital.schema';
import { User, UserDocument } from '../schema/user.schema';
import { Doctor, DoctorDocument } from '../schema/doctor.schema';
import { CreateAppointmentDto } from 'src/dto/create-appoitment.dto';
import * as fs from 'fs';
import * as path from 'path';

import { AppointmentFilterRequestDto } from 'src/dto/requests/appointment-filter-request.dto';

@Injectable()
export class AppointmentService {
  constructor(
    @InjectModel(Appointment.name)
    private appointmentModel: Model<AppointmentDocument>,
    @InjectModel(Hospital.name)
    private hospitalModel: Model<HospitalDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Doctor.name) private doctorModel: Model<DoctorDocument>,
  ) { }

  isValidDate(dateString: string): boolean {
    const regex = /^\d{4}[-/]\d{1,2}[-/]\d{1,2}$/;
    if (!regex.test(dateString)) return false;

    const [year, month, day] = dateString.split(/[-/]/).map(Number);

    // Kiểm tra phạm vi cơ bản
    if (month < 1 || month > 12 || day < 1 || day > 31) return false;

    const date = new Date(year, month - 1, day);

    return (
      date.getFullYear() === year &&
      date.getMonth() === month - 1 &&
      date.getDate() === day
    );
  }

  async create(
    createAppointmentDto: CreateAppointmentDto,
  ): Promise<Appointment> {
    const { user, doctor, hospitalName, appointmentDate, appointmentTime } =
      createAppointmentDto;
    // Kiểm tra user tồn tại
    if (!(await this.userModel.findById(user))) {
      throw new Error('User not found');
    }
    // Kiểm tra doctor tồn tại và lấy thông tin
    const doctorData = await this.doctorModel.findById(doctor);
    if (!doctorData) {
      throw new Error('Doctor not found');
    }
    // Kiểm tra hospitalName không rỗng
    const hospital = await this.hospitalModel.findOne({ name: hospitalName });
    if (!hospital) {
      throw new Error('Hospital not found');
    }

    if (!this.isValidDate(appointmentDate)) {
      throw new Error('Invalid appointment date');
    }

    // Kiểm tra appointmentDate trong workingDays
    const parsedDate = new Date(appointmentDate);
    const weekdayMap = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      0: 'Sunday',
    };
    const dayOfWeek = weekdayMap[parsedDate.getDay()];
    if (!doctorData.workingDays.includes(dayOfWeek)) {
      throw new Error(`Doctor does not work on ${dayOfWeek}`);
    }
    // Kiểm tra appointmentDate >= hôm nay
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (parsedDate < today) {
      throw new Error('Appointment date must be today or in the future');
    }
    // Kiểm tra appointmentTime trong giờ làm việc và không trùng lịch
    const [startStr, endStr] = appointmentTime.split(' - ');
    const startHour = parseInt(startStr.split(':')[0]);
    const endHour = parseInt(endStr.split(':')[0]);
    const doctorStartHour = parseInt(doctorData.startTime.split(':')[0]);
    const doctorEndHour = parseInt(doctorData.endTime.split(':')[0]);
    if (startHour < doctorStartHour || endHour > doctorEndHour) {
      throw new Error(
        `Appointment time must be within ${doctorData.startTime} - ${doctorData.endTime}`,
      );
    }
    // Kiểm tra trùng lịch
    const existingAppointments = await this.appointmentModel.find({
      doctor,
      appointmentDate,
      appointmentTime,
    });
    if (existingAppointments.length > 0) {
      throw new Error('Time slot is already booked');
    }
    // Lưu lịch hẹn
    const createdAppointment =
      this.appointmentModel.create(createAppointmentDto);
    return createdAppointment;
  }

  // Lấy tất cả các cuộc hẹn
  async getAllAppointments(): Promise<Appointment[]> {
    return this.appointmentModel.find().populate('user doctor').exec();
  }

  // Lấy các cuộc hẹn của một người dùng cụ thể
  async getAppointmentsByUserId(userId: string): Promise<Appointment[]> {
    return this.appointmentModel
      .find({ user: userId })
      .populate('user doctor')
      .exec();
  }

  // Lấy các cuộc hẹn của một bác sĩ cụ thể
  async getAppointmentsByDoctorId(doctorId: string): Promise<Appointment[]> {
    return this.appointmentModel
      .find({ doctor: doctorId })
      .populate('user doctor')
      .exec();
  }

  // Lấy cuộc hẹn theo ID cụ thể
  async getAppointmentById(appointmentId: string): Promise<Appointment> {
    return this.appointmentModel
      .findById(appointmentId)
      .populate('user doctor')
      .exec();
  }

  async cancelAppointment(appointmentId: string): Promise<any> {
    const appointment = await this.appointmentModel.findById(appointmentId);
    if (!appointment) {
      throw new Error('Appointment not found');
    }
    await appointment.deleteOne();
    return { message: 'Appointment cancelled successfully' };
  }

  async updateAppointment(
    appointmentId: string,
    updateData: Partial<CreateAppointmentDto>,
  ): Promise<any> {
    const appointment = await this.appointmentModel.findByIdAndUpdate(
      appointmentId,
      updateData,
      { new: true }, // Trả về document đã cập nhật
    );
    if (!appointment) {
      throw new Error('Appointment not found');
    }
    return appointment;
  }

  //Phú
  async getDoctorsWithAppointments() {
    return this.appointmentModel.aggregate([
      { $group: { _id: '$doctorId', count: { $sum: 1 } } }, // Nhóm theo doctorId
      {
        $lookup: { // Kết hợp với bảng Doctor để lấy thông tin bác sĩ
          from: 'doctors',
          localField: '_id',
          foreignField: '_id',
          as: 'doctorInfo',
        },
      },
      { $unwind: '$doctorInfo' }, // Giải phóng mảng doctorInfo
      { $project: { _id: 0, doctorId: '$_id', doctorInfo: 1, appointmentCount: '$count' } },
    ]);
  }
  //Phước
  async filterAppointmentsByMonth(month: number, year: number): Promise<Appointment[]> {
    // Validate month and year
    if (month < 1 || month > 12) {
      throw new BadRequestException('Invalid month. Month must be between 1 and 12');
    }

    if (year < 2000 || year > 2100) {
      throw new BadRequestException('Invalid year');
    }

    // Tạo ngày đầu và cuối tháng
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    // Tìm các cuộc hẹn trong khoảng thời gian
    const appointments = await this.appointmentModel
      .find({
        appointmentDate: {
          $gte: startDate,
          $lte: endDate
        }
      })
      .populate({
        path: 'user',
        select: '-password'
      })
      .populate({
        path: 'doctor',
        select: '-password'
      })
      .sort({ appointmentDate: 1, appointmentTime: 1 })
      .exec();

    return appointments;
  }

  // Nghĩa
  async filterAppointments(
    filter: AppointmentFilterRequestDto,
  ): Promise<Appointment[]> {
    let appointment = await this.appointmentModel.find()
      .populate({
        path: 'user',
        select: '-password'
      })
      .populate({
        path: 'doctor',
        select: '-password'
      })
      .sort({ appointmentDate: 1, appointmentTime: 1 })
      .exec();

    let filtered = appointment;

    if (filter.doctor !== undefined) {
      const doctor = await this.doctorModel.findOne({ name: filter.doctor }).select('-password').exec();
      if (!doctor) {
        throw new Error('Doctor not found');
      }
      filtered = filtered.filter((item) => {
        console.log(item.doctor, doctor.name);
        return item.doctor._id.toString() === doctor._id.toString();
      });
    }
    if (filter.year !== undefined) {
      if (filter.year < 2000 || filter.year > 2100) {
        throw new Error('Invalid year');
      }
      filtered = filtered.filter((item) => {
        return new Date(item.appointmentDate).getFullYear() == filter.year;
      });
    }
    if (filter.month !== undefined) {
      if (filter.month < 1 || filter.month > 12) {
        throw new Error('Invalid month');
      }
      filtered = filtered.filter((item) => {
        return new Date(item.appointmentDate).getMonth() + 1 == filter.month;
      });
    }
    if (filter.date !== undefined) {
      if (filter.date < 1 || filter.date > 31) {
        throw new Error('Invalid date');
      }
      filtered = filtered.filter((item) => {
        return new Date(item.appointmentDate).getDate() == filter.date;
      });
    }

    return filtered.sort((a, b) => {
      const dateA = new Date(a.appointmentDate);
      const dateB = new Date(b.appointmentDate);
      return dateB.getTime() - dateA.getTime();
    });
  }
}
