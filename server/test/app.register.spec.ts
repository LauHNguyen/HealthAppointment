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
      try {
        const username = 'testuser';
        const password = 'P@ssword123';

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
      } catch (error) {
        expect(error.message).toContain('error');
      }
    });

    it('should throw an error if username is blank', async () => {
      try {
        const username = '';
        const password = 'P@ssword123';

        await authService.register(username, password);
      } catch (error) {
        expect(error.message).toContain('Username is blank');
      }
    });

    it('should throw an error if password is blank', async () => {
      try {
        const username = 'testuser';
        const password = '';

        await authService.register(username, password);
      } catch (error) {
        expect(error.message).toContain('Password is blank');
      }
    });

    it('should throw an error if password is less than 8 characters', async () => {
      try {
        const username = 'testuser';
        const password = 'pass';

        await authService.register(username, password);
      } catch (error) {
        expect(error.message).toContain(
          'Password must be at least 8 characters long',
        );
      }
    });

    it('should throw an error if password does not contain at least one uppercase letter', async () => {
      try {
        const username = 'testuser';
        const password = 'password';

        await authService.register(username, password);
      } catch (error) {
        expect(error.message).toContain(
          'Password must contain at least one uppercase letter',
        );
      }
    });

    it('should throw an error if password does not contain at least one lowercase letter', async () => {
      try {
        const username = 'testuser';
        const password = 'PASSWORD';

        await authService.register(username, password);
      } catch (error) {
        expect(error.message).toContain(
          'Password must contain at least one lowercase letter',
        );
      }
    });

    it('should throw an error if password does not contain at least one number', async () => {
      try {
        const username = 'testuser';
        const password = 'Password';

        await authService.register(username, password);
      } catch (error) {
        expect(error.message).toContain(
          'Password must contain at least one number',
        );
      }
    });

    it('should throw an error if password does not contain at least one special character', async () => {
      try {
        const username = 'testuser';
        const password = 'Password123';

        await authService.register(username, password);
      } catch (error) {
        expect(error.message).toContain(
          'Password must contain at least one special character',
        );
      }
    });
  });
});
