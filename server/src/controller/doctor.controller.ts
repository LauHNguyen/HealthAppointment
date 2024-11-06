import { Controller, Get, Query } from '@nestjs/common';
import { DoctorService } from '../services/doctor.service';

@Controller('doctor')
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
  async filterDoctors(
    @Query('district') district?: string,
    @Query('hospitalName') hospitalName?: string,
  ) {
    return this.doctorService.filterDoctors(district, hospitalName);
  }
}
