import { Controller, Post, Body, Get, Param, Delete, Patch, BadRequestException, Query } from '@nestjs/common';
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
        throw new Error('Create failed');
      }
      return new ApiResponse(200, 'Create successfully', response);
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

  @Get('filter/month')
  async filterByMonth(
    @Query('month') month: number,
    @Query('year') year: number
  ) {
    try {
      const appointments = await this.appointmentService.filterAppointmentsByMonth(month, year);
      return new ApiResponse(200, 'Appointments retrieved successfully', appointments);
    } catch (error) {
      throw new BadRequestException({
        statusCode: 400,
        message: error.message,
      });
    }
  }

  @Post('load-data')
  async loadAppointmentsData() {
    try {
      const result = await this.appointmentService.loadAppointmentsFromJson();
      return new ApiResponse(200, result.message, result);
    } catch (error) {
      throw new BadRequestException({
        statusCode: 400,
        message: error.message,
      });
    }
  }
}
