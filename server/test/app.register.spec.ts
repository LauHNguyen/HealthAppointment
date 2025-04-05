import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from '../src/services/auth.service';
import { JwtService } from '@nestjs/jwt';
import { User } from '../src/schema/user.schema';
import { Doctor } from '../src/schema/doctor.schema';
import * as bcrypt from 'bcrypt'; // Mock bcrypt
import { getModelToken } from '@nestjs/mongoose';

jest.mock('bcrypt'); // Mock toàn bộ bcrypt

describe('AuthService', () => {
  let authService: AuthService;
  let userModel: any;
  let doctorModel: any;

  beforeEach(async () => {
    const mockUserModel = {
      create: jest.fn(),
      save: jest.fn(),
    };
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
          useValue: mockUserModel,
        },
        {
          provide: getModelToken(Doctor.name), // Mock DoctorModel
          useValue: {},
        },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
    userModel = module.get(getModelToken(User.name)); // Đảm bảo lấy đúng mô hình User
    doctorModel = module.get(getModelToken(Doctor.name)); // Đảm bảo lấy đúng mô hình Doctor
  });

  it('should define AuthService', () => {
    expect(authService).toBeDefined();
  });

  describe('register', () => {
    it('register a new user successfully', async () => {
      const username = 'testuser';
      const password = 'password123';

      const hashedPassword = 'hashed_password123';

      // Mock bcrypt.hash để trả về hashedPassword cụ thể
      jest.spyOn(bcrypt, 'hash' as any).mockResolvedValue(hashedPassword);

      // Mock userModel.save để trả về đối tượng người dùng sau khi save
      const newUser = {
        username,
        password: hashedPassword,
      };

      // Mock phương thức create trong mockUserModel để trả về newUser
      userModel.create.mockResolvedValue({
        ...newUser,
        save: jest.fn().mockResolvedValue(newUser), // Mô phỏng hành vi của save
      });

      jest
        .spyOn(authService, 'generateAccessToken')
        .mockReturnValue('mocked_token');

      const result = await authService.register(username, password);

      expect(result).toEqual({
        access_token: 'mocked_token',
        user: {
          username,
          password: hashedPassword,
          save: expect.any(Function),
        },
      });
    });
  });
});
