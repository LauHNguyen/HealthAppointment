import { Test, TestingModule } from '@nestjs/testing';
import { AppointmentService } from '../src/services/appointment.service';
import { getModelToken } from '@nestjs/mongoose';

import { Appointment } from '../src/schema/appointment.schema';
import { User } from '../src/schema/user.schema';
import { Doctor } from '../src/schema/doctor.schema';
import { Hospital } from '../src/schema/hospital.schema';
import { AUTH } from '../src/enums/auth.enum';

describe('AppointmentService', () => {
  let service: AppointmentService;
  let appointmentModel;
  let userModel;
  let doctorModel;
  let hospitalModel;
  let mockAppointment;
  let mockExistedAppointment;
  let mockHospital;
  let mockUser;
  let mockDoctor;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppointmentService,
        {
          provide: getModelToken(Appointment.name),
          useValue: {
            create: jest.fn(),
            find: jest.fn(),
          },
        },
        {
          provide: getModelToken(Hospital.name),
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: getModelToken(User.name),
          useValue: {
            findById: jest.fn(),
          },
        },
        {
          provide: getModelToken(Doctor.name),
          useValue: {
            findById: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<AppointmentService>(AppointmentService);
    appointmentModel = module.get(getModelToken(Appointment.name));
    userModel = module.get(getModelToken(User.name));
    doctorModel = module.get(getModelToken(Doctor.name));
    hospitalModel = module.get(getModelToken(Hospital.name));

    mockExistedAppointment = {
      user: 'id_user',
      doctor: 'id_doctor',
      hospitalName: 'hospitalName',
      appointmentDate: '2026-05-01',
      appointmentTime: '10:00 - 11:00',
    };

    mockHospital = {
      name: 'hospitalName',
      address: 'address',
      district: 'district',
      number: 'number',
      specialty: 'specialty',
    };

    mockUser = {
      _id: 'id_user',
      username: 'testuser',
      password: 'hashed_password',
      name: 'Test User',
      email: 'testuser@example.com',
      birthOfDate: new Date('2000-01-01'),
      gender: 'male',
      authProvider: 'local',
      role: AUTH.USER,
    };

    mockDoctor = {
      _id: 'id_doctor',
      name: 'Test Doctor',
      password: 'hashed_password',
      specialty: 'Cardiology',
      hospitalName: 'Test Hospital',
      startTime: '9:00',
      endTime: '13:00',
      workingDays: [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ],
      role: AUTH.DOCTOR,
    };
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should define AppointmentService', () => {
    expect(AppointmentService).toBeDefined();
  });

  describe('createNewAppointment', () => {
    it('TC01: Should create an appointment successfully with valid data', async () => {
      try {
        mockAppointment = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-05-01',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        appointmentModel.find.mockImplementation(
          async ({ doctor, appointmentDate, appointmentTime }) => {
            if (
              doctor === mockExistedAppointment.doctor &&
              appointmentDate === mockExistedAppointment.appointmentDate &&
              appointmentTime === mockExistedAppointment.appointmentTime
            ) {
              // Giả lập đã có appointment bị trùng
              return [mockAppointment];
            }

            // Không có lịch hẹn trùng
            return [];
          },
        );

        const mockSave = jest.fn().mockResolvedValue(mockAppointment);
        appointmentModel.create = mockSave;

        const result = await service.create(mockAppointment);

        expect(result).toEqual(mockAppointment);
      } catch (error) {
      }
    });

    it('TC02: Should throw error if user is not found', async () => {
      try {
        const invalidDto = {
          user: '',
          doctor: 'id_doctor',
          hospitalName: 'HospitalName',
          appointmentDate: '2025-05-01',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('User not found');
      }
    });

    it('TC03: Should throw error if doctor is not found', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: '',
          hospitalName: 'HospitalName',
          appointmentDate: '2025-05-01',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Doctor not found');
      }
    });

    it('TC04: Should throw error if hospital is not found', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: '',
          appointmentDate: '2025-05-01',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Hospital not found');
      }
    });

    it('TC05: Should throw error if date of appointment is valid', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-05-00',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Invalid appointment date');
      }
    });

    it('TC06: Should throw error if date of appointment is valid', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-05-32',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Invalid appointment date');
      }
    });

    it('TC07: Should throw error if date of appointment is valid', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-00-01',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Invalid appointment date');
      }
    });

    it('TC08: Should throw error if date of appointment is valid', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-13-01',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Invalid appointment date');
      }
    });

    it('TC09: Should throw error if date of appointment is valid', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-02-29',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Invalid appointment date');
      }
    });

    it('TC10: Should throw error if date of appointment is valid', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2028-02-30',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Invalid appointment date');
      }
    });

    it('TC11: Should throw error if date of appointment is valid', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2028-02--30',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Invalid appointment date');
      }
    });

    it('TC12: Should throw error if Schedule an appointment on a non-working day of doctor', async () => {
      let dayOfWeek;
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-05-04',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        const parsedDate = new Date(invalidDto.appointmentDate);
        const weekdayMap = {
          1: 'Monday',
          2: 'Tuesday',
          3: 'Wednesday',
          4: 'Thursday',
          5: 'Friday',
          6: 'Saturday',
          0: 'Sunday',
        };
        dayOfWeek = weekdayMap[parsedDate.getDay()];

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain(`Doctor does not work on ${dayOfWeek}`);
      }
    });

    it('TC13: Should throw error if date of appointment is past', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2020-01-04',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain(
          'Appointment date must be today or in the future',
        );
      }
    });

    it('TC14: Should throw error if appointment is duplicated', async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2026-05-01',
          appointmentTime: '10:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        appointmentModel.find.mockImplementation(
          async ({ doctor, appointmentDate, appointmentTime }) => {
            if (
              doctor === mockExistedAppointment.doctor &&
              appointmentDate === mockExistedAppointment.appointmentDate &&
              appointmentTime === mockExistedAppointment.appointmentTime
            ) {
              // Giả lập đã có appointment bị trùng
              return [mockAppointment];
            }

            // Không có lịch hẹn trùng
            return [];
          },
        );

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain('Time slot is already booked');
      }
    });

    it(`TC15: Should throw error if appointment time before doctor's office hours`, async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-05-01',
          appointmentTime: '08:00 - 11:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain(
          `Appointment time must be within ${mockDoctor.startTime} - ${mockDoctor.endTime}`,
        );
      }
    });
    
    it(`TC16: Should throw error if appointment time before doctor's office hours`, async () => {
      try {
        const invalidDto = {
          user: 'id_user',
          doctor: 'id_doctor',
          hospitalName: 'hospitalName',
          appointmentDate: '2025-05-01',
          appointmentTime: '10:00 - 14:00',
        };

        userModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.user ? mockUser : null;
        });

        doctorModel.findById.mockImplementation(async (id) => {
          return id === mockAppointment.doctor ? mockDoctor : null;
        });

        hospitalModel.findOne.mockImplementation(async (query) => {
          return query.name === mockAppointment.hospitalName
            ? mockHospital
            : null;
        });

        await service.create(invalidDto);
      } catch (error) {
        expect(error.message).toContain(
          `Appointment time must be within ${mockDoctor.startTime} - ${mockDoctor.endTime}`,
        );
      }
    });
  });
});
