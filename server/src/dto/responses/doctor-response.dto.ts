import { Exclude } from 'class-transformer';

export class DoctorResponseDto {
  _id: string;

  name: string;

  specialty: string;

  hospitalName: string;

  startTime: string;

  endTime: string;

  workingDays: string[];

  role: string;

  @Exclude()
  password: string;

  @Exclude()
  __v: number;
}
