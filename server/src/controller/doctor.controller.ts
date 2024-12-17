import { Controller, Get, NotFoundException, Param, Query, Req, UseGuards } from '@nestjs/common';
import { DoctorService } from '../services/doctor.service';
import { JwtAuthGuard } from 'src/configuration/jwt-auth.guard';
import { Request } from 'express';

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
    return this.doctorService.filterDoctors(hospitalName);
  }
  @Get('id')
    async getCurrentDoctorId(@Req() req: Request) {
    // Lấy doctor từ request đã được giải mã thông qua JWT Guard
    const doctor: any = req.user; // doctor đã được xác thực
    return { userId: doctor.id }; // Trả về ID bác sĩ
    }
  @Get(':id')
  async getDoctorById(@Param('id') id: string) {
    const doctor = await this.doctorService.getDoctorById(id);
    if (!doctor) {
      throw new NotFoundException(`Doctor with ID ${id} not found`);
    }
    return doctor;
  }
}