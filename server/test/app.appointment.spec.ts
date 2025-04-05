import { Test, TestingModule } from '@nestjs/testing';
import { AppointmentService } from '../src/services/appointment.service';
import { getModelToken } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Appointment } from '../src/schema/appointment.schema';
import { BadRequestException } from '@nestjs/common';

describe('AppointmentService - create', () => {
  let service: AppointmentService;
  let appointmentModel: Model<Appointment>;

  // Mock model
  const mockAppointmentModel = {
    constructor: jest.fn().mockImplementation((dto) => ({
      ...dto,
      save: jest.fn().mockResolvedValue(dto),
    })),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppointmentService,
        {
          provide: getModelToken('Appointment'),
          useValue: mockAppointmentModel,
        },
      ],
    }).compile();

    service = module.get<AppointmentService>(AppointmentService);
    appointmentModel = module.get<Model<Appointment>>(getModelToken('Appointment'));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('TC1: Should create appointment successfully with valid data', async () => {
    const dto = {
      user: '67233bfb196c0855e66d87a0', // Valid ObjectId
      doctor: '675d7a991f6ad2f0a5a1024e', // Valid ObjectId
      hospitalName: 'Bệnh viện Từ Dũ',
      appointmentDate: '2025-05-01',
      appointmentTime: '10:00 - 11:00',
    };
    const result = await service.create(dto);
    expect(result).toEqual(dto);
    expect(mockAppointmentModel.constructor).toHaveBeenCalledWith(dto);
  });

  it('TC2: Should throw error if user is empty', async () => {
    const dto = {
      user: '',
      doctor: '675d7a991f6ad2f0a5a1024e',
      hospitalName: 'Bệnh viện Từ Dũ',
      appointmentDate: '2025-05-01',
      appointmentTime: '10:00 - 11:00',
    };
    // DTO validation sẽ throw lỗi trước khi vào service
    await expect(service.create(dto)).rejects.toThrow(BadRequestException);
  });

  it('TC3: Should throw error if doctor is empty', async () => {
    const dto = {
      user: '67233bfb196c0855e66d87a0',
      doctor: '',
      hospitalName: 'Bệnh viện Từ Dũ',
      appointmentDate: '2025-05-01',
      appointmentTime: '10:00 - 11:00',
    };
    await expect(service.create(dto)).rejects.toThrow(BadRequestException);
  });

  it('TC4: Should throw error if hospitalName is empty', async () => {
    const dto = {
      user: '67233bfb196c0855e66d87a0',
      doctor: '675d7a991f6ad2f0a5a1024e',
      hospitalName: '',
      appointmentDate: '2025-05-01',
      appointmentTime: '10:00 - 11:00',
    };
    await expect(service.create(dto)).rejects.toThrow(BadRequestException);
  });

  it('TC5: Should throw error if appointmentDate is invalid', async () => {
    const dto = {
      user: '67233bfb196c0855e66d87a0',
      doctor: '675d7a991f6ad2f0a5a1024e',
      hospitalName: 'Bệnh viện Từ Dũ',
      appointmentDate: '1/5/2025',
      appointmentTime: '10:00 - 11:00',
    };
    await expect(service.create(dto)).rejects.toThrow(BadRequestException);
  });

  it('TC6: Should throw error if user is invalid ObjectId', async () => {
    const dto = {
      user: 'invalid-id',
      doctor: '675d7a991f6ad2f0a5a1024e',
      hospitalName: 'Bệnh viện Từ Dũ',
      appointmentDate: '2025-05-01',
      appointmentTime: '10:00 - 11:00',
    };
    mockAppointmentModel.constructor.mockImplementation(() => ({
      save: jest.fn().mockRejectedValue(new Error('Cast to ObjectId failed')),
    }));
    await expect(service.create(dto)).rejects.toThrow('Cast to ObjectId failed');
  });

  it('TC7: Should throw error if appointmentTime is empty', async () => {
    const dto = {
      user: '67233bfb196c0855e66d87a0',
      doctor: '675d7a991f6ad2f0a5a1024e',
      hospitalName: 'Bệnh viện Từ Dũ',
      appointmentDate: '2025-05-01',
      appointmentTime: '',
    };
    await expect(service.create(dto)).rejects.toThrow(BadRequestException);
  });
});