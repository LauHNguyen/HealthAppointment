import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from '../src/services/auth.service';
import { JwtService } from '@nestjs/jwt';
import { User } from '../src/schema/user.schema';
import { Doctor } from '../src/schema/doctor.schema';
import { AUTH } from '../src/enums/auth.enum';
import * as bcrypt from 'bcrypt'; // Mock bcrypt
import { getModelToken } from '@nestjs/mongoose';

describe('AuthService', () => {
  let authService: AuthService;
  let userModel;
  let doctorModel;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: JwtService,
          useValue: {
            sign: jest.fn().mockReturnValue('mocked_token'), // Mock JwtService để trả về token giả
          },
        },
        {
          provide: getModelToken(User.name), // Mock UserModel
          useValue: {
            findOne: jest.fn(), // Mock phương thức findOne
          },
        },
        {
          provide: getModelToken(Doctor.name), // Mock DoctorModel
          useValue: {
            findOne: jest.fn(), // Mock phương thức findOne
          },
        },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
    userModel = module.get(getModelToken(User.name)); // Đảm bảo lấy đúng mô hình User
    doctorModel = module.get(getModelToken(Doctor.name)); // Đảm bảo lấy đúng mô hình Doctor
  });

  describe('login', () => {
    it('should return an access token on successful login', async () => {
      const mockUser: User = {
        username: 'testuser',
        password: 'hashed_password', // Giả sử mật khẩu đã được hash
        name: 'Test User',
        email: 'testuser@example.com',
        birthOfDate: new Date('2000-01-01'),
        gender: 'male',
        authProvider: 'local',
        role: AUTH.USER,
      };

      // Giả lập phương thức findOne trả về user mock
      userModel.findOne.mockResolvedValue(mockUser); // Sử dụng mockResolvedValue thay vì gán lại hàm

      // Mock bcrypt.compare để trả về true
      jest
        .spyOn(bcrypt, 'compare')
        .mockImplementation(() => Promise.resolve(true));

      // Mock phương thức generateAccessToken
      jest
        .spyOn(authService, 'generateAccessToken')
        .mockReturnValue('mocked_token');

      const result = await authService.login(
        'testuser',
        'correct_password',
        AUTH.USER,
      );

      expect(result.access_token).toBe('mocked_token'); // Kiểm tra token trả về có đúng không
    });

    it('should return an access token for doctor login on successful login', async () => {
      const mockDoctor: Doctor = {
        name: 'Test Doctor', // Chỉ cần một thuộc tính name
        password: 'hashed_password', // Giả sử mật khẩu đã được hash
        specialty: 'Cardiology',
        hospitalName: 'Test Hospital', // HospitalName là một thuộc tính bắt buộc
        startTime: '6:00',
        endTime: '18:00',
        workingDays: [
          'Thứ Hai',
          'Thứ Ba',
          'Thứ Tư',
          'Thứ Năm',
          'Thứ Sáu',
          'Thứ Bảy',
          'Chủ Nhật',
        ],
        role: AUTH.DOCTOR,
      };

      // Giả lập phương thức findOne trả về doctor mock
      doctorModel.findOne.mockResolvedValue(mockDoctor);

      jest
        .spyOn(bcrypt, 'compare')
        .mockImplementation(() => Promise.resolve(true));
        
      jest
        .spyOn(authService, 'generateAccessToken')
        .mockReturnValue('mocked_token');

      const result = await authService.login(
        'testdoctor',
        'correct_password',
        AUTH.DOCTOR,
      );

      expect(result.access_token).toBe('mocked_token');
    });
  });
});
