import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Doctor, DoctorSchema } from '../schema/doctor.schema';
import { DoctorService } from '../services/doctor.service';
import { DoctorController } from '../controller/doctor.controller';
import { HospitalModule } from './hospital.module';

@Module({
  imports: [MongooseModule.forFeature([{ name: Doctor.name, schema: DoctorSchema }]),
  HospitalModule,],
  
  controllers: [DoctorController],
  providers: [DoctorService],
})
export class DoctorModule {}
