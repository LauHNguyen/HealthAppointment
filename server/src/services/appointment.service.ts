import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Appointment, AppointmentDocument } from '../schema/appointment.schema';
import { User, UserDocument } from '../schema/user.schema';
import { Doctor, DoctorDocument } from '../schema/doctor.schema';
import { CreateAppointmentDto } from 'src/dto/create-appoitment.dto';

@Injectable()
export class AppointmentService {
  constructor(
    @InjectModel(Appointment.name) private appointmentModel: Model<AppointmentDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Doctor.name) private doctorModel: Model<DoctorDocument>,
  ) {}

  async create(createAppointmentDto: CreateAppointmentDto): Promise<Appointment> {
   const createdAppointment = new this.appointmentModel(createAppointmentDto);
   return createdAppointment.save();
 }

    // Lấy tất cả các cuộc hẹn
  async getAllAppointments(): Promise<Appointment[]> {
   return this.appointmentModel.find().populate('user doctor').exec();
 }

 // Lấy các cuộc hẹn của một người dùng cụ thể
 async getAppointmentsByUserId(userId: string): Promise<Appointment[]> {
   return this.appointmentModel
     .find({ user: userId })
     .populate('user doctor')
     .exec();
 }

 // Lấy các cuộc hẹn của một bác sĩ cụ thể
 async getAppointmentsByDoctorId(doctorId: string): Promise<Appointment[]> {
   return this.appointmentModel
     .find({ doctor: doctorId })
     .populate('user doctor')
     .exec();
 }

 // Lấy cuộc hẹn theo ID cụ thể
 async getAppointmentById(appointmentId: string): Promise<Appointment> {
   return this.appointmentModel
     .findById(appointmentId)
     .populate('user doctor')
     .exec();
 }

 async cancelAppointment(appointmentId: string): Promise<any> {
  const appointment = await this.appointmentModel.findById(appointmentId);
  if (!appointment) {
    throw new Error('Appointment not found');
  }
  await appointment.deleteOne();
  return { message: 'Appointment cancelled successfully' };
}

async updateAppointment(appointmentId: string, updateData: Partial<CreateAppointmentDto>): Promise<any> {
  const appointment = await this.appointmentModel.findByIdAndUpdate(
    appointmentId,
    updateData,
    { new: true }, // Trả về document đã cập nhật
  );
  if (!appointment) {
    throw new Error('Appointment not found');
  }
  return appointment;
}


}
