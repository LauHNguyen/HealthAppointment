import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AppointmentController } from '../controller/appointment.controller';
import { AppointmentService } from '../services/appointment.service';
import { Appointment, AppointmentSchema } from '../schema/appointment.schema';
import { Hospital, HospitalSchema } from '../schema/hospital.schema';
import { Doctor, DoctorSchema } from '../schema/doctor.schema';
import { User, UserSchema } from '../schema/user.schema';
import { AppointmentManegementController } from '../controller/admin/appointment-management.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Appointment.name, schema: AppointmentSchema },
      { name: Hospital.name, schema: HospitalSchema },
      { name: Doctor.name, schema: DoctorSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [AppointmentController, AppointmentManegementController],
  providers: [AppointmentService],
})
export class AppointmentModule {}
