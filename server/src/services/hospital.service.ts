import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Hospital } from '../schema/hospital.schema';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class HospitalService {
  private readonly filePath = path.join(process.cwd(), 'data/hospitals.json');

  constructor(@InjectModel(Hospital.name) private hospitalModel: Model<Hospital>) {}

  async loadHospitals() {
    const data = JSON.parse(fs.readFileSync(this.filePath, 'utf-8'));
  
    // Lấy tên các bệnh viện từ file JSON
    const hospitalNamesFromJson = data.map((h) => h.name);
  
    // Xóa bệnh viện trong MongoDB nếu không có trong JSON
    await this.hospitalModel.deleteMany({ name: { $nin: hospitalNamesFromJson } });
  
    for (const hospitalData of data) {
      // Tìm bệnh viện theo tên trong cơ sở dữ liệu
      const existingHospital = await this.hospitalModel.findOne({ name: hospitalData.name });
  
      if (!existingHospital) {
        // Nếu bệnh viện chưa tồn tại, thêm mới
        const hospital = new this.hospitalModel(hospitalData);
        await hospital.save();
      } else if (
        existingHospital.address !== hospitalData.address ||
        existingHospital.district !== hospitalData.district
      ) {
        // Nếu bệnh viện đã tồn tại nhưng có thay đổi về địa chỉ hoặc quận, cập nhật lại
        await this.hospitalModel.updateOne(
          { name: hospitalData.name },
          { $set: { address: hospitalData.address, district: hospitalData.district, number: hospitalData.number, specialty: hospitalData.specialty } },
        );
      }
    }
  
    // Trả về danh sách bệnh viện đã cập nhật từ MongoDB
    return this.hospitalModel.find();
  }
  

  async getHospitals() {
    return this.hospitalModel.find().exec();
  }
  
  async findByDistrict(district: string) {
    return this.hospitalModel.find({ district }).exec();
  }
  
  async findByName(hospitalName: string) {
    return this.hospitalModel.findOne({ name: hospitalName }).exec();
  }
  
}
