import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { DoctorService } from '../services/doctor.service';
import { JwtAuthGuard } from 'src/configuration/jwt-auth.guard';
import { Request } from 'express';
import { Doctor } from 'src/schema/doctor.schema';
import { ApiResponse } from '../dto/responses/api-response.dto';

@Controller('doctor')
@UseGuards(JwtAuthGuard)
export class DoctorController {
  constructor(private readonly doctorService: DoctorService) {}

  @Get('/load')
  async loadDoctors() {
    return this.doctorService.loadDoctors();
  }

  @Get()
  async getDoctors() {
    return this.doctorService.getDoctors();
  }

  @Get('filter')
  async filterDoctors(@Query('hospitalName') hospitalName?: string) {
    try {
      let response = await this.doctorService.filterDoctors(hospitalName);
      if (!response) {
        throw new error('list of doctors is empty');
      }
      return new ApiResponse(200, 'this is list of doctors', response);
    } catch (error) {
      throw new BadRequestException({
        statusCode: 400,
        message: error.message,
      });
    }
  }

  @Get('id')
  async getCurrentDoctorId(@Req() req: Request) {
    // Lấy doctor từ request đã được giải mã thông qua JWT Guard
    const doctor: any = req.user; // doctor đã được xác thực
    console.log('Request doc:', doctor);
    return { userId: doctor.id }; // Trả về ID bác sĩ
  }

  @Get('profile')
  async getProfile(@Req() req: Request) {
    const doctor: any = req.user;
    console.log('Request Body:', doctor);
    return await this.doctorService.getDoctorProfile(doctor.id);
  }

  @Get(':id')
  async getDoctorById(@Param('id') id: string) {
    try {
      const doctor = await this.doctorService.getDoctorById(id);
      if (!doctor) {
        throw new Error(`Doctor with ID ${id} not found`);
      }
      return new ApiResponse(200, 'this is list of doctors', doctor);
    } catch (error) {
      throw new BadRequestException({
        statusCode: 400,
        message: error.message,
      });
    }
  }

  @Put('update')
  async updateUser(@Req() req: Request, @Body() updateData: Partial<Doctor>) {
    // Lấy userId từ token đã xác thực
    const doctorId = req.user['id'];
    // Gọi service để cập nhật thông tin
    return this.doctorService.updateDoctor(doctorId, updateData);
  }
}
