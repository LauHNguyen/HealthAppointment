import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Doctor, DoctorDocument } from '../schema/doctor.schema';
import { HospitalService } from './hospital.service';

import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class DoctorService {
  private readonly filePath = path.join(process.cwd(), 'data/doctors.json');

  constructor(@InjectModel(Doctor.name) private doctorModel: Model<DoctorDocument>,private hospitalModel: HospitalService,) {}

  async loadDoctors() {
    // Đọc dữ liệu từ file JSON
    const data = JSON.parse(fs.readFileSync(this.filePath, 'utf-8'));

    // Lấy danh sách tên bác sĩ từ file JSON
    const doctorNamesFromJson = data.map((d) => d.name);

    // Xóa bác sĩ trong MongoDB nếu không có trong JSON
    await this.doctorModel.deleteMany({ name: { $nin: doctorNamesFromJson } });

    for (const doctorData of data) {
      // Tìm bác sĩ theo tên trong cơ sở dữ liệu
      const existingDoctor = await this.doctorModel.findOne({ name: doctorData.name });

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
              hospitalName: doctorData.hospitalName
            }
          }
        );
      }
    }

    // Trả về danh sách bác sĩ đã cập nhật từ MongoDB
    return this.doctorModel.find();
  }

  async getDoctors() {
    return this.doctorModel.find().exec();
  }

  async getDoctorById(id: string): Promise<Doctor> {
    const doctor = await this.doctorModel.findById(id).exec();
    if (!doctor) {
      throw new NotFoundException(`Doctor with ID ${id} not found`);
    }
    return doctor;
  }

  async filterDoctors(district?: string, hospitalName?: string) {
   // Nếu không có tên bệnh viện nhưng có quận
   if (!hospitalName && district) {
     const hospitalsInDistrict = await this.hospitalModel.findByDistrict(district);
     
     // Lấy danh sách tên bệnh viện trong quận
     const hospitalNamesInDistrict = hospitalsInDistrict.map(hospital => hospital.name);
 
     // Lọc bác sĩ theo danh sách tên bệnh viện
     return this.doctorModel.find({ hospitalName: { $in: hospitalNamesInDistrict } }).exec();
   }
 
   // Nếu có tên bệnh viện
   if (hospitalName) {
     const hospital = await this.hospitalModel.findByName(hospitalName);
     if (!hospital) {
       return []; // Hoặc throw new NotFoundException('Hospital not found');
     }
 
     // Lọc bác sĩ theo tên bệnh viện (không cần kiểm tra specialty)
     return this.doctorModel.find({ hospitalName }).exec();
   }
 
   // Nếu không có điều kiện nào thì trả về tất cả bác sĩ
   return this.doctorModel.find().exec();
 }
 
}
