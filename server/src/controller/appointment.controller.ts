import { Controller, Post, Body, Get, Param, Delete, Patch } from '@nestjs/common';
import { AppointmentService } from '../services/appointment.service';
import { CreateAppointmentDto } from 'src/dto/create-appoitment.dto';
import { ApiResponse } from 'src/dto/responses/api-response.dto';
import { BadRequestError } from 'openai';
import { error } from 'console';

@Controller('appointment')
export class AppointmentController {
  constructor(private readonly appointmentService: AppointmentService) {}

  @Get()
  async getAllAppointments() {
    return this.appointmentService.getAllAppointments();
  }

  // Lấy các cuộc hẹn theo ID người dùng
  @Get('user/:userId')
  async getAppointmentsByUserId(@Param('userId') userId: string) {
    return this.appointmentService.getAppointmentsByUserId(userId);
  }

  // Lấy các cuộc hẹn theo ID bác sĩ
  @Get('doctor/:doctorId')
  async getAppointmentsByDoctorId(@Param('doctorId') doctorId: string) {
    return this.appointmentService.getAppointmentsByDoctorId(doctorId);
  }

  // Lấy cuộc hẹn theo ID
  @Get(':appointmentId')
  async getAppointmentById(@Param('appointmentId') appointmentId: string) {
    return this.appointmentService.getAppointmentById(appointmentId);
  }

  @Post('create')
  async create(@Body() createAppointmentDto: CreateAppointmentDto) {
    try {
      let response = await this.appointmentService.create(createAppointmentDto);
      if (!response) {
        throw new error('Create failed');
      }
      return ApiResponse(200, 'Create successfully', response);
    }
    catch (error) {
      throw new BadRequestException({
              statusCode: 400,
              message: error.message,
            });
    }
  }

  @Delete(':appointmentId')
  async cancelAppointment(@Param('appointmentId') appointmentId: string) {
    return this.appointmentService.cancelAppointment(appointmentId);
  }

  @Patch(':appointmentId')
  async updateAppointment(
    @Param('appointmentId') appointmentId: string,
    @Body() updateAppointmentDto: Partial<CreateAppointmentDto>,
  ) {
    return this.appointmentService.updateAppointment(appointmentId, updateAppointmentDto);
  }
}
