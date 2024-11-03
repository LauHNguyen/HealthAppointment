import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Hospital } from '../schema/hospital.schema';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class HospitalService {
  private readonly filePath = path.join(__dirname, '../../data/hospitals.json');

  constructor(@InjectModel(Hospital.name) private hospitalModel: Model<Hospital>) {}

  async loadHospitals() {
    const data = JSON.parse(fs.readFileSync(this.filePath, 'utf-8'));
    for (const hospitalData of data) {
      const existingHospital = await this.hospitalModel.findOne({ name: hospitalData.name });
      if (!existingHospital) {
        const hospital = new this.hospitalModel(hospitalData);
        await hospital.save();
      }
    }
    return this.hospitalModel.find();
  }

  async getHospitals() {
    return this.hospitalModel.find().exec();
  }
}
