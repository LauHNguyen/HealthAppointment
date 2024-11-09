import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AppointmentController } from '../controller/appointment.controller';
import { AppointmentService } from '../services/appointment.service';
import { Appointment, AppointmentSchema } from '../schema/appointment.schema';

import { Doctor, DoctorSchema } from 'src/schema/doctor.schema';
import { User, UserSchema } from 'src/schema/user.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Appointment.name, schema: AppointmentSchema },
      { name: Doctor.name, schema: DoctorSchema },
      { name: User.name, schema: UserSchema }
    ]),
  ],
  controllers: [AppointmentController],
  providers: [AppointmentService],
})
export class AppointmentModule {}