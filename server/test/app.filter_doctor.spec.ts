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
  let mockHospitals;
  let mockDoctors;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DoctorService,
        {
          provide: getModelToken(Doctor.name),
          useValue: {
            find: jest.fn(),
          },
        },
        {
          provide: HospitalService,
          useValue: {
            findByName: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<DoctorService>(DoctorService);
    doctorModel = module.get(getModelToken(Doctor.name));
    hospitalModel = module.get<HospitalService>(HospitalService);

    mockHospitals = [
      { name: 'Hospital A', _id: 'id1' },
      { name: 'Hospital B', _id: 'id2' },
    ];

    mockDoctors = [
      { name: 'Dr. A', hospitalName: 'Hospital A' },
      { name: 'Dr. B', hospitalName: 'Hospital B' },
    ];
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should define DoctorService', () => {
    expect(DoctorService).toBeDefined();
  });

  describe('filterDoctors', () => {
    it('TC01: should filter doctors successfully with one name of hospital', async () => {
      try {
        const mockDataFilter = {
          hospitalName: 'Hospital A',
        };

        hospitalModel.findByName = jest
          .fn()
          .mockImplementation((name) =>
            Promise.resolve(mockHospitals.find((h) => h.name === name)),
          );

        doctorModel.find = jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue(mockDoctors),
        });

        const result = await service.filterDoctors(mockDataFilter.hospitalName);
        expect(result).toEqual(mockDoctors);
      } catch (error) {
        expect(error.message).toContain('error');
      }
    });

    it('TC02: should filter doctors successfully with many name of hospital', async () => {
      try {
        const mockDataFilter = {
          hospitalName: ['Hospital A', 'Hospital B'],
        };

        hospitalModel.findByName = jest
          .fn()
          .mockImplementation((name) =>
            Promise.resolve(mockHospitals.find((h) => h.name === name)),
          );

        doctorModel.find = jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue(mockDoctors),
        });

        const result = await service.filterDoctors(mockDataFilter.hospitalName);
        expect(result).toEqual(mockDoctors);
      } catch (error) {
        expect(error.message).toContain('error');
      }
    });

    it('TC03: should throw error if hospitalName is empty', async () => {
      try {
        const mockDataFilter = {
          hospitalName: [],
        };

        hospitalModel.findByName = jest
          .fn()
          .mockImplementation((name) =>
            Promise.resolve(mockHospitals.find((h) => h.name === name)),
          );

        doctorModel.find = jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue(mockDoctors),
        });

        const result = await service.filterDoctors(mockDataFilter.hospitalName);
        expect(result).toEqual(mockDoctors);
      } catch (error) {
        expect(error.message).toContain('No hospital names provided');
      }
    });

    it('TC04: should throw error if hospitalName is empty', async () => {
      let notFoundHospitals;
      try {
        const mockDataFilter = {
          hospitalName: 'adlkjhaskjdh',
        };

        const names = Array.isArray(mockDataFilter.hospitalName)
          ? mockDataFilter.hospitalName
          : [mockDataFilter.hospitalName];

        hospitalModel.findByName = jest
          .fn()
          .mockImplementation((name) =>
            Promise.resolve(mockHospitals.find((h) => h.name === name)),
          );

        notFoundHospitals = names.filter(
          (name, index) => !hospitalModel.findByName[index],
        );

        doctorModel.find = jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue(mockDoctors),
        });

        const result = await service.filterDoctors(mockDataFilter.hospitalName);
        expect(result).toEqual(mockDoctors);
      } catch (error) {
        expect(error.message).toContain(
          `Hospitals with names ${notFoundHospitals.join(', ')} not found`,
        );
      }
    });
  });
});
