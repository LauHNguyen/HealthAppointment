import { Module } from '@nestjs/common';
import { HospitalService } from '../services/hospital.service';
import { HospitalController } from '../controller/hospital.controller';
import { MongooseModule } from '@nestjs/mongoose';
import { Hospital, HospitalSchema } from 'src/schema/hospital.schema';

@Module({
  imports: [MongooseModule.forFeature([{ name: Hospital.name, schema: HospitalSchema }])],
  controllers: [HospitalController],
  providers: [HospitalService],
  exports: [HospitalService],
})
export class HospitalModule {}
