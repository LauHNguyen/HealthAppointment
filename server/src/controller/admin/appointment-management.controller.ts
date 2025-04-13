import { BadRequestException, Body, Controller, Post } from '@nestjs/common';
import { AppointmentFilterRequestDto } from '../../dto/requests/appointment-filter-request.dto';
import { ApiResponse } from '../../dto/responses/api-response.dto';
import { AppointmentService } from '../../services/appointment.service';

@Controller('admin/appointment')
export class AppointmentManegementController {
  

  constructor(private readonly appointmentService: AppointmentService) {}

  @Post('filter')
  async filterAppointments(
    @Body() appointmentfilter: Partial<AppointmentFilterRequestDto>,
  ) {
    try {
      let result =
        await this.appointmentService.filterAppointments(appointmentfilter);
      return new ApiResponse(200, 'Filter successfully', result);
    } catch (error) {
      throw new BadRequestException({
        statusCode: 400,
        message: error.message,
      });
    }
  }
}
