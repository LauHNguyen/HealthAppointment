import { Test, TestingModule } from '@nestjs/testing';
import { AppointmentService } from '../src/services/appointment.service';
import { getModelToken } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Appointment } from '../src/schema/appointment.schema';
import { User } from '../src/schema/user.schema';
import { Doctor } from '../src/schema/doctor.schema';

describe('AppointmentService', () => {
  let service: AppointmentService;
  let appointmentModel;
  let userModel;
  let doctorModel;

  beforeEach(async () => {
    const mockAppointmentModel = jest.fn().mockImplementation((dto) => ({
      ...dto,
      save: jest.fn().mockResolvedValue(dto),
    }));

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppointmentService,
        {
          provide: getModelToken(Appointment.name),
          useValue: mockAppointmentModel,
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
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    it('TC1: should create an appointment successfully with valid data', async () => {
      const mockAppointment = {
        user: '67233bfb196c0855e66d87a0',
        doctor: '675d7a991f6ad2f0a5a1024e',
        hospitalName: 'Bệnh viện Từ Dũ',
        appointmentDate: '2025-05-01',
        appointmentTime: '10:00 - 11:00',
      };

      userModel.findById.mockResolvedValue({ _id: mockAppointment.user });
      doctorModel.findById.mockResolvedValue({ _id: mockAppointment.doctor });

      const result = await service.create(mockAppointment);

      expect(result).toEqual(mockAppointment);
      expect(appointmentModel).toHaveBeenCalledWith(mockAppointment);
    });

    it('TC2: should throw error if user is empty', async () => {
      const invalidDto = {
        user: '',
        doctor: '675d7a991f6ad2f0a5a1024e',
        hospitalName: 'Bệnh viện Từ Dũ',
        appointmentDate: '2025-05-01',
        appointmentTime: '10:00 - 11:00',
      };

      jest.spyOn(service, 'create').mockRejectedValue(new Error('User cannot be empty'));

      await expect(service.create(invalidDto)).rejects.toThrow('User cannot be empty');
    });

    it('TC3: should throw error if doctor is empty', async () => {
      const invalidDto = {
        user: '67233bfb196c0855e66d87a0',
        doctor: '',
        hospitalName: 'Bệnh viện Từ Dũ',
        appointmentDate: '2025-05-01',
        appointmentTime: '10:00 - 11:00',
      };

      jest.spyOn(service, 'create').mockRejectedValue(new Error('Doctor cannot be empty'));

      await expect(service.create(invalidDto)).rejects.toThrow('Doctor cannot be empty');
    });

    it('TC4: should throw error if hospitalName is empty', async () => {
      const invalidDto = {
        user: '67233bfb196c0855e66d87a0',
        doctor: '675d7a991f6ad2f0a5a1024e',
        hospitalName: '',
        appointmentDate: '2025-05-01',
        appointmentTime: '10:00 - 11:00',
      };

      jest.spyOn(service, 'create').mockRejectedValue(new Error('Hospital name cannot be empty'));

      await expect(service.create(invalidDto)).rejects.toThrow('Hospital name cannot be empty');
    });

    it('TC5: should throw error if appointmentDate is invalid', async () => {
      const invalidDto = {
        user: '67233bfb196c0855e66d87a0',
        doctor: '675d7a991f6ad2f0a5a1024e',
        hospitalName: 'Bệnh viện Từ Dũ',
        appointmentDate: '1/5/2025',
        appointmentTime: '10:00 - 11:00',
      };

      jest.spyOn(service, 'create').mockRejectedValue(new Error('Invalid appointment date'));

      await expect(service.create(invalidDto)).rejects.toThrow('Invalid appointment date');
    });

    it('TC6: should throw error if appointmentDate is empty', async () => {
      const invalidDto = {
        user: '67233bfb196c0855e66d87a0',
        doctor: '675d7a991f6ad2f0a5a1024e',
        hospitalName: 'Bệnh viện Từ Dũ',
        appointmentDate: '',
        appointmentTime: '10:00 - 11:00',
      };

      userModel.findById.mockResolvedValue(null);
      jest.spyOn(service, 'create').mockRejectedValue(new Error('Appointment date cannot be empty'));

      await expect(service.create(invalidDto)).rejects.toThrow('Appointment date cannot be empty');
    });

    it('TC7: should throw error if appointmentTime is empty', async () => {
      const invalidDto = {
        user: '67233bfb196c0855e66d87a0',
        doctor: '675d7a991f6ad2f0a5a1024e',
        hospitalName: 'Bệnh viện Từ Dũ',
        appointmentDate: '2025-05-01',
        appointmentTime: '',
      };

      jest.spyOn(service, 'create').mockRejectedValue(new Error('Appointment time cannot be empty'));

      await expect(service.create(invalidDto)).rejects.toThrow('Appointment time cannot be empty');
    });
  });
});