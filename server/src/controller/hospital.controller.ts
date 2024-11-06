import { Controller, Get } from '@nestjs/common';
import { HospitalService } from '../services/hospital.service';

@Controller('hospital')
export class HospitalController {
  constructor(private readonly hospitalService: HospitalService) {}

  @Get('/load')
  async loadHospitals() {
    return this.hospitalService.loadHospitals();
  }

  @Get()
  async getHospitals() {
  return this.hospitalService.getHospitals();
}

}
