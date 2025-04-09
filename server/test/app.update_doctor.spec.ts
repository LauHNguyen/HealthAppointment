import { Test, TestingModule } from '@nestjs/testing';
import { DoctorService } from '../src/services/doctor.service';
import { HospitalService } from '../src/services/hospital.service';
import { getModelToken } from '@nestjs/mongoose';

import { Doctor } from '../src/schema/doctor.schema';
import { Hospital } from '../src/schema/hospital.schema';
import { AUTH } from '../src/enums/auth.enum';
import { plainToInstance } from 'class-transformer';
import { DoctorResponseDto } from '../src/dto/responses/doctor-response.dto';
import { validate } from 'class-validator';

describe('DoctorService', () => {
  let service: DoctorService;
  let hospitalService: HospitalService;
  let doctorModel;
  let hospitalModel;
  let mockDoctor;
  let id = 'id_doctor';
  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DoctorService,
        {
          provide: getModelToken(Doctor.name),
          useValue: {
            findById: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: HospitalService,
          useValue: {},
        },
      ],
    }).compile();

    service = module.get<DoctorService>(DoctorService);
    doctorModel = module.get(getModelToken(Doctor.name));
    hospitalModel = module.get<HospitalService>(HospitalService);

    mockDoctor = {
      _id: 'id_doctor',
      name: 'Test Doctor',
      password: 'hashed_password',
      specialty: 'Cardiology',
      hospitalName: 'Test Hospital',
      startTime: '09:00',
      endTime: '13:00',
      workingDays: [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ],
      role: AUTH.DOCTOR,
      save: jest.fn().mockResolvedValue(true),
      toObject: jest.fn(function () {
        return {
          startTime: this.startTime,
          endTime: this.endTime,
          workingDays: this.workingDays,
        };
      }),
    };
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should define DoctorService', () => {
    expect(DoctorService).toBeDefined();
  });

  describe(`updateDoctor`, () => {
    it(`TC01: Should update successfully a doctor`, async () => {
      try {
        const mockUpdateDoctor = {
          startTime: '09:00',
          endTime: '17:00',
          workingDays: ['Monday', 'Tuesday', 'Saturday', 'Sunday'],
        };

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id ? mockDoctor : null;
        });

        const result = await service.updateDoctor(id, mockUpdateDoctor);

        mockUpdateDoctor.startTime = service.normalizeTime(
          mockUpdateDoctor.startTime,
        );
        mockUpdateDoctor.endTime = service.normalizeTime(
          mockUpdateDoctor.endTime,
        );

        expect(result).toEqual(mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain(`Error`);
      }
    });

    it('TC02: Should throw error if doctor is not found', async () => {
      try {
        const mockUpdateDoctor = {
          startTime: '09:00',
          endTime: '17:00',
          workingDays: ['Monday', 'Tuesday', 'Saturday', 'Sunday'],
        };

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id + '123' ? mockDoctor : null;
        });

        await service.updateDoctor(id + '123', mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain('Doctor not found');
      }
    });

    it('TC03: Should throw error if working days is wrong format', async () => {
      try {
        const mockUpdateDoctor = {
          startTime: '09:00',
          endTime: '17:00',
          workingDays: [],
        };

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id ? mockDoctor : null;
        });

        await service.updateDoctor(id, mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain('Working days cannot be empty');
      }
    });

    it('TC04: Should throw error if working days is wrong format', async () => {
      let invalidDays;
      try {
        const mockUpdateDoctor = {
          startTime: '09:00',
          endTime: '17:00',
          workingDays: ['ThangMatDay'],
        };

        const validWeekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];

        invalidDays = mockUpdateDoctor.workingDays.filter(
          (day) => !validWeekdays.includes(day),
        );

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id ? mockDoctor : null;
        });

        await service.updateDoctor(id, mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain(
          `Invalid working days: ${invalidDays.join(', ')}`,
        );
      }
    });

    it('TC05: should throw error if startTime out of range', async () => {
      try {
        const mockUpdateDoctor = {
          startTime: '04:00',
          endTime: '17:00',
          workingDays: ['Monday', 'Tuesday'],
        };

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id ? mockDoctor : null;
        });

        await service.updateDoctor(id, mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain(
          'Invalid startTime. Must be between 6:00 and 18:00',
        );
      }
    });

    it('TC06: should throw error if startTime out of range', async () => {
      try {
        const mockUpdateDoctor = {
          startTime: '19:00',
          endTime: '17:00',
          workingDays: ['Monday', 'Tuesday'],
        };

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id ? mockDoctor : null;
        });

        await service.updateDoctor(id, mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain(
          'Invalid startTime. Must be between 6:00 and 18:00',
        );
      }
    });

    it('TC07: should throw error if endTime out of range', async () => {
      try {
        const mockUpdateDoctor = {
          startTime: '09:00',
          endTime: '05:00',
          workingDays: ['Monday', 'Tuesday'],
        };

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id ? mockDoctor : null;
        });

        await service.updateDoctor(id, mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain(
          'Invalid endTime. Must be between 6:00 and 18:00',
        );
      }
    });

    it('TC08: should throw error if endTime out of range', async () => {
      try {
        const mockUpdateDoctor = {
          startTime: '09:00',
          endTime: '19:00',
          workingDays: ['Monday', 'Tuesday'],
        };

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id ? mockDoctor : null;
        });

        await service.updateDoctor(id, mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain(
          'Invalid endTime. Must be between 6:00 and 18:00',
        );
      }
    });

    // điều kiện đần thật sự
    it('TC09: should throw error if dortor works less than 8 hours', async () => {
      try {
        const mockUpdateDoctor = {
          startTime: '09:00',
          endTime: '10:00',
          workingDays: ['Monday', 'Tuesday'],
        };

        doctorModel.findById.mockImplementation(async (id) => {
          return id === id ? mockDoctor : null;
        });

        await service.updateDoctor(id, mockUpdateDoctor);
      } catch (error) {
        expect(error.message).toContain(
          'Working time must be at least 8 hours',
        );
      }
    });
  });
});
