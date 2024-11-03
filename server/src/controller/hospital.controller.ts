import { Controller, Get } from '@nestjs/common';
import { HospitalService } from '../services/hospital.service';

@Controller('hospital')
export class HospitalController {
  constructor(private readonly hospitalService: HospitalService) {}

  @Get()
  async getHospitals() {
    return this.hospitalService.loadHospitals();
  }
}
