import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Doctor, DoctorDocument } from '../schema/doctor.schema';
import { HospitalService } from './hospital.service';

import * as fs from 'fs';
import * as path from 'path';
import { DoctorResponseDto } from '../dto/responses/doctor-response.dto';
import { plainToInstance } from 'class-transformer';

@Injectable()
export class DoctorService {
  private readonly filePath = path.join(process.cwd(), 'data/doctors.json');

  constructor(
    @InjectModel(Doctor.name) private doctorModel: Model<DoctorDocument>,
    private hospitalModel: HospitalService,
  ) { }

  async loadDoctors() {
    // Đọc dữ liệu từ file JSON
    const data = JSON.parse(fs.readFileSync(this.filePath, 'utf-8'));

    // Lấy danh sách tên bác sĩ từ file JSON
    const doctorNamesFromJson = data.map((d) => d.name);

    // Xóa bác sĩ trong MongoDB nếu không có trong JSON
    await this.doctorModel.deleteMany({ name: { $nin: doctorNamesFromJson } });

    for (const doctorData of data) {
      // Tìm bác sĩ theo tên trong cơ sở dữ liệu
      const existingDoctor = await this.doctorModel.findOne({
        name: doctorData.name,
      });

      if (!existingDoctor) {
        // Nếu bác sĩ chưa tồn tại, thêm mới
        const doctor = new this.doctorModel(doctorData);
        await doctor.save();
      } else if (
        existingDoctor.specialty !== doctorData.specialty ||
        existingDoctor.hospitalName !== doctorData.hospitalName
      ) {
        // Nếu bác sĩ đã tồn tại nhưng có thay đổi thông tin, cập nhật lại
        await this.doctorModel.updateOne(
          { name: doctorData.name },
          {
            $set: {
              specialty: doctorData.specialty,
              hospitalName: doctorData.hospitalName,
            },
          },
        );
      }
    }

    // Trả về danh sách bác sĩ đã cập nhật từ MongoDB
    return this.doctorModel.find();
  }

  async getDoctors() {
    return this.doctorModel.find().exec();
  }
  async findByDoctorname(name: string): Promise<Doctor | null> {
    return this.doctorModel.findOne({ name }).exec();
  }

  async filterDoctors(hospitalName?: string | string[]) {
    const names = Array.isArray(hospitalName) ? hospitalName : [hospitalName];
    if (!names || names.length === 0) {
      throw new Error('No hospital names provided');
    }

    const hospitals = await Promise.all(
      names.map((name) => this.hospitalModel.findByName(name)),
    );

    const notFoundHospitals = names.filter((name, index) => !hospitals[index]);
    if (notFoundHospitals.length > 0) {
      throw new Error(
        `Hospitals with names ${notFoundHospitals.join(', ')} not found`,
      );
    }

    return this.doctorModel.find({ hospitalName: { $in: names } }).exec();
  }
  async getDoctorById(id: string): Promise<Doctor> {
    const doctor = await this.doctorModel.findById(id).exec();
    if (!doctor) {
      throw new NotFoundException(`Doctor with ID ${id} not found`);
    }
    return doctor;
  }

  async updateDoctor(
    doctorId: string,
    updateData: Partial<Doctor>,
  ): Promise<DoctorResponseDto> {
    // Danh sách ngày hợp lệ
    const validWeekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    // Danh sách giờ hợp lệ (từ giao diện)
    const validTimes = Array.from(
      { length: 13 },
      (_, i) => `${String(i + 6).padStart(2, '0')}:00`,
    );
    // Kiểm tra doctorId tồn tại
    const existingDoctor = await this.doctorModel.findById(doctorId);
    if (!existingDoctor) {
      throw new Error('Doctor not found');
    }
    // Kiểm tra workingDays

    if (
      !Array.isArray(updateData.workingDays) ||
      updateData.workingDays.length === 0
    ) {
      throw new Error('Working days cannot be empty');
    }

    const invalidDays = updateData.workingDays.filter(
      (day) => !validWeekdays.includes(day),
    );

    if (invalidDays.length > 0) {
      throw new Error(`Invalid working days: ${invalidDays.join(', ')}`);
    }

    // Kiểm tra startTime và endTime
    const { startTime, endTime } = updateData;
    const normalizedStartTime = this.normalizeTime(startTime);
    const normalizedEndTime = this.normalizeTime(endTime);

    if (startTime || endTime) {
      // Kiểm tra định dạng và giá trị hợp lệ
      if (!validTimes.includes(normalizedStartTime)) {
        throw new Error('Invalid startTime. Must be between 6:00 and 18:00');
      }
      if (!validTimes.includes(normalizedEndTime)) {
        throw new Error('Invalid endTime. Must be between 6:00 and 18:00');
      }
      // Kiểm tra khoảng cách thời gian
      const startHour = parseInt(normalizedStartTime.split(':')[0]);
      const endHour = parseInt(normalizedEndTime.split(':')[0]);
      let workingHours = endHour - startHour;

      // Nếu endHour nhỏ hơn startHour, giả định ca làm việc qua ngày hôm sau
      if (workingHours < 0) {
        workingHours += 24; // Cộng thêm 24 giờ
      }

      if (workingHours < 8) {
        throw new Error('Working time must be at least 8 hours');
      }
    }

    // Cập nhật dữ liệu
    existingDoctor.workingDays = updateData.workingDays;
    existingDoctor.startTime = normalizedStartTime;
    existingDoctor.endTime = normalizedEndTime;

    existingDoctor.save();
    return plainToInstance(DoctorResponseDto, existingDoctor.toObject());
  }

  async getDoctorProfile(doctorId: string): Promise<Doctor> {
    return await this.doctorModel
      .findById(doctorId)
      .select('-password -_id -__v');
  }

  normalizeTime(time: string): string {
    const [hourStr, minute] = time.split(':');
    const hour = parseInt(hourStr, 10);
    return `${String(hour).padStart(2, '0')}:${minute}`;
  }
}
