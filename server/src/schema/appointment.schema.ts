import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { User } from './user.schema';
import { Doctor } from './doctor.schema';

export type AppointmentDocument = Appointment & Document;

@Schema()
export class Appointment {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  user: User;

  @Prop({ type: Types.ObjectId, ref: 'Doctor', required: true })
  doctor: Doctor;

  @Prop({ required: true })
  hospitalName: string; // Có thể lấy từ thông tin của bác sĩ

  @Prop({ required: true })
  appointmentDate: Date; // Ngày khám

  @Prop({ required: true })
  appointmentTime: string; // Thời gian khám, định dạng như "HH:mm"

  @Prop({ default: Date.now })
  createdAt: Date; // Thời gian tạo đơn
}

export const AppointmentSchema = SchemaFactory.createForClass(Appointment);
