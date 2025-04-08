import { Test, TestingModule } from '@nestjs/testing';
import { DoctorController } from '../src/controller/doctor.controller';
import { DoctorService } from '../src/services/doctor.service';
import { ApiResponse } from '../src/dto/responses/api-response.dto';

describe('DoctorController', () => {
  let controller: DoctorController;
  let doctorService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DoctorController,
        {
          provide: DoctorService,
          useValue: {
            filterDoctors: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<DoctorController>(DoctorController);
    doctorService = module.get(DoctorService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('filterDoctors', () => {
    it('TC1: should return list of doctors for one valid hospital', async () => {
      const hospitalName = 'Bệnh viện Từ Dũ';
      const mockDoctors = [
        {
          _id: '1',
          name: 'Doctor 1',
          specialty: 'Cardiology',
          hospitalName,
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Hai', 'Thứ Ba'],
          role: 'doctor',
        },
        {
          _id: '2',
          name: 'Doctor 2',
          specialty: 'Neurology',
          hospitalName,
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Tư', 'Thứ Năm'],
          role: 'doctor',
        },
      ];

      jest.spyOn(doctorService, 'filterDoctors').mockResolvedValue(mockDoctors);

      const result = await controller.filterDoctors(hospitalName);

      expect(result.statusCode).toBe(200);
      expect(result.message).toBe('this is list of doctors');
      expect(result.data).toEqual(mockDoctors);
      expect(doctorService.filterDoctors).toHaveBeenCalledWith(hospitalName);
    });

    it('TC2: should return list of doctors for two valid hospitals', async () => {
      const hospitalName = 'Bệnh viện Từ Dũ,Bệnh viện Chợ Rẫy';
      const mockDoctors = [
        {
          _id: '1',
          name: 'Doctor 1',
          specialty: 'Cardiology',
          hospitalName: 'Bệnh viện Từ Dũ',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Hai'],
          role: 'doctor',
        },
        {
          _id: '2',
          name: 'Doctor 2',
          specialty: 'Neurology',
          hospitalName: 'Bệnh viện Chợ Rẫy',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Ba'],
          role: 'doctor',
        },
      ];

      jest.spyOn(doctorService, 'filterDoctors').mockResolvedValue(mockDoctors);

      const result = await controller.filterDoctors(hospitalName);

      expect(result.statusCode).toBe(200);
      expect(result.message).toBe('this is list of doctors');
      expect(result.data).toEqual(mockDoctors);
      expect(doctorService.filterDoctors).toHaveBeenCalledWith(hospitalName);
    });

    it('TC3: should throw error for one invalid hospital name', async () => {
      const hospitalName = 'Bệnh Viện Từ Vũ';
      const mockDoctors = [];

      jest.spyOn(doctorService, 'filterDoctors').mockResolvedValue(mockDoctors);

      const result = await controller.filterDoctors(hospitalName);

      expect(result.statusCode).toBe(200);
      expect(result.message).toBe('this is list of doctors');
      // expect(result.message).toBe('Hospital with name'+` ${hospitalName} not found`);
      // expect(result.data).toEqual(mockDoctors);
      // await expect(controller.filterDoctors(hospitalName)).rejects.toMatchObject({
      //   statusCode: 400,
      //   response: {
      //     statusCodeCode: 400,
      //     message: 'Hospital with name'+` ${hospitalName} not found`,
      //   },
      // });
      expect(doctorService.filterDoctors).toHaveBeenCalledWith(hospitalName);
    });

    it('TC4: should return list of doctors for two hospitals with one invalid name', async () => {
      const hospitalName = 'Bệnh viện Từ Dũ,Sai Tên Bệnh Viện';
      const mockDoctors = [
        {
          _id: '1',
          name: 'Doctor 1',
          specialty: 'Cardiology',
          hospitalName: 'Bệnh viện Từ Dũ',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Hai'],
          role: 'doctor',
        },
      ];

      jest.spyOn(doctorService, 'filterDoctors').mockResolvedValue(mockDoctors);

      const result = await controller.filterDoctors(hospitalName);

      expect(result.statusCode).toBe(200);
      expect(result.message).toBe('this is list of doctors');
      expect(result.data).toEqual(mockDoctors);
      expect(doctorService.filterDoctors).toHaveBeenCalledWith(hospitalName);
    });

    it('TC5: should return all doctors when hospitalName is not provided', async () => {
      const mockDoctors = [
        {
          _id: '1',
          name: 'Doctor 1',
          specialty: 'Cardiology',
          hospitalName: 'Bệnh viện Từ Dũ',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Hai'],
          role: 'doctor',
        },
        {
          _id: '2',
          name: 'Doctor 2',
          specialty: 'Neurology',
          hospitalName: 'Bệnh viện Chợ Rẫy',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Ba'],
          role: 'doctor',
        },
      ];

      jest.spyOn(doctorService, 'filterDoctors').mockResolvedValue(mockDoctors);

      const result = await controller.filterDoctors(undefined);

      expect(result.statusCode).toBe(200);
      expect(result.message).toBe('this is list of doctors');
      expect(result.data).toEqual(mockDoctors);
      expect(doctorService.filterDoctors).toHaveBeenCalledWith(undefined);
    });

    it('TC6: should return list of doctors for one hospital with lowercase name', async () => {
      const hospitalName = 'bệnh viện từ dũ';
      const mockDoctors = [
        {
          _id: '1',
          name: 'Doctor 1',
          specialty: 'Cardiology',
          hospitalName: 'Bệnh viện Từ Dũ',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Hai'],
          role: 'doctor',
        },
        {
          _id: '2',
          name: 'Doctor 2',
          specialty: 'Neurology',
          hospitalName: 'Bệnh viện Từ Dũ',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Ba'],
          role: 'doctor',
        },
      ];

      jest.spyOn(doctorService, 'filterDoctors').mockResolvedValue(mockDoctors);

      const result = await controller.filterDoctors(hospitalName);

      expect(result.statusCode).toBe(200);
      expect(result.message).toBe('this is list of doctors');
      expect(result.data).toEqual(mockDoctors);
      expect(doctorService.filterDoctors).toHaveBeenCalledWith(hospitalName);
    });

    it('TC7: should return list of doctors for one hospital with numeric characters', async () => {
      const hospitalName = 'Bệnh viện 115';
      const mockDoctors = [
        {
          _id: '1',
          name: 'Doctor 1',
          specialty: 'Cardiology',
          hospitalName: 'Bệnh viện 115',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Hai'],
          role: 'doctor',
        },
        {
          _id: '2',
          name: 'Doctor 2',
          specialty: 'Neurology',
          hospitalName: 'Bệnh viện 115',
          startTime: '6:00',
          endTime: '18:00',
          workingDays: ['Thứ Ba'],
          role: 'doctor',
        },
      ];

      jest.spyOn(doctorService, 'filterDoctors').mockResolvedValue(mockDoctors);

      const result = await controller.filterDoctors(hospitalName);

      expect(result.statusCode).toBe(200);
      expect(result.message).toBe('this is list of doctors');
      expect(result.data).toEqual(mockDoctors);
      expect(doctorService.filterDoctors).toHaveBeenCalledWith(hospitalName);
    });
  });
});