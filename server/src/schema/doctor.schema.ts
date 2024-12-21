import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import * as bcrypt from 'bcrypt';

export type DoctorDocument = Doctor & Document;

@Schema()
export class Doctor {
  @Prop({ required: true })
  name: string;

  @Prop()
  password: string;

  @Prop({ required: true })
  specialty: string;

  @Prop({ required: true })
  hospitalName: string;

  @Prop({ type: String, default:"6:00"})
  startTime: string; 

  @Prop({ type: String, default:"18:00"})
  endTime: string; 

  @Prop({ type: [String], default:['Thứ Hai','Thứ Ba','Thứ Tư','Thứ Năm','Thứ Sáu','Thứ Bảy','Chủ Nhật',]})
  workingDays: string[]; 

  @Prop({required: true, default: 'doctor'})
  role: string
}

export const DoctorSchema = SchemaFactory.createForClass(Doctor);

DoctorSchema.pre('save', async function (next) {
  const doctor = this as DoctorDocument;

  // Nếu password chưa được thiết lập, mã hóa name để làm password mặc định
  if (!doctor.password) {
    doctor.password = await bcrypt.hash(doctor.name, 10);
  }

  next(); 
});