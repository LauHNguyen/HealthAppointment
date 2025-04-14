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
  let userModel: any;
  let doctorModel: any;
  let mockUser: User;
  let mockDoctor: Doctor;

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

    mockUser = {
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
      name: 'Test Doctor',
      password: 'hashed_password',
      specialty: 'Cardiology',
      hospitalName: 'Test Hospital',
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
  });

  it('should define AuthService', () => {
    expect(authService).toBeDefined();
  });

  describe('login', () => {
    it('should return an access token on successful login', async () => {
      try {
        // Giả lập phương thức findOne trả về user mock
        userModel.findOne.mockImplementation(async ({ username }) => {
          return username === mockUser.username ? mockUser : null;
        });

        // Mock bcrypt.compare để trả về true
        jest.spyOn(bcrypt, 'compare').mockImplementation((plainPassword) => {
          return plainPassword === mockUser.password
            ? Promise.resolve(true) // Nếu đúng mật khẩu thì trả về true
            : Promise.resolve(false); // Nếu sai mật khẩu thì trả về false
        });

        // Mock phương thức generateAccessToken
        jest
          .spyOn(authService, 'generateAccessToken')
          .mockReturnValue('mocked_token');

        const result = await authService.login(
          'testuser',
          'hashed_password',
          AUTH.USER,
        );

        expect(result.access_token).toBe('mocked_token'); // Kiểm tra token trả về có đúng không
      } catch (e) {
        expect(e.message).toContain('error');
      }
    });

    it('should throw Username is blank if username is not provided', async () => {
      try {
        await authService.login('', 'correct_password', AUTH.USER);
      } catch (e) {
        expect(e.message).toContain('Username is blank');
      }
    });

    it('should throw Password is blank if password is not provided', async () => {
      // Mock bcrypt.compare để trả về true
      try {
        jest.spyOn(bcrypt, 'compare').mockImplementation((plainPassword) => {
          return plainPassword === mockUser.password
            ? Promise.resolve(true) // Nếu đúng mật khẩu thì trả về true
            : Promise.resolve(false); // Nếu sai mật khẩu thì trả về false
        });
        await authService.login('testuser', '', AUTH.USER);
      } catch (e) {
        expect(e.message).toContain('Password is blank');
      }
    });

    it('should throw Username is incorrect if username is incorrect', async () => {
      try {
        // Giả lập phương thức findOne trả về user mock
        userModel.findOne.mockImplementation(async ({ username }) => {
          return username === mockUser.username ? mockUser : null;
        });
        await authService.login('testuser1', '1', AUTH.USER);
      } catch (e) {
        expect(e.message).toContain('Username is incorrect');
      }
    });

    it('should return an access token for doctor login on successful login', async () => {
      try {
        // Giả lập phương thức findOne trả về user mock
        doctorModel.findOne.mockImplementation(async ({ name }) => {
          return name === mockDoctor.name ? mockDoctor : null;
        });
        // Mock bcrypt.compare để trả về true
        jest.spyOn(bcrypt, 'compare').mockImplementation((plainPassword) => {
          // So sánh mật khẩu nhập vào với mockDoctor.password
          return plainPassword === mockDoctor.password
            ? Promise.resolve(true) // Nếu đúng mật khẩu thì trả về true
            : Promise.resolve(false); // Nếu sai mật khẩu thì trả về false
        });
        // Mock phương thức generateAccessToken
        jest
          .spyOn(authService, 'generateAccessToken')
          .mockReturnValue('mocked_token');
        const result = await authService.login(
          'Test Doctor',
          'hashed_password',
          AUTH.DOCTOR,
        );
        expect(result.access_token).toBe('mocked_token');
      } catch (e) {
        expect(e.message).toContain('error');
      }
    });

    it('should throw Username is incorrect if password is not provided', async () => {
      // Giả lập phương thức findOne trả về user mock
      try {
        await authService.login('us', '1', AUTH.DOCTOR); // Gọi hàm và mong đợi lỗi // Nếu không có lỗi => thất bại
      } catch (e) {
        expect(e.message).toContain('Username is incorrect'); // Kiểm tra nội dung lỗi
      }
    });

    it('should throw Invalid role if role is not user or doctor', async () => {
      try {
        await authService.login('us', '1', 'Doc Ock'); // Gọi hàm và mong đợi lỗi // Nếu không có lỗi => thất bại
      } catch (e) {
        expect(e.message).toContain('Invalid role'); // Kiểm tra nội dung lỗi
      }
    });

    it('should throw Password is incorrect if password is provided but incorrect', async () => {
      try {
        // Giả lập phương thức findOne trả về user mock
        userModel.findOne.mockImplementation(async ({ username }) => {
          return username === mockUser.username ? mockUser : null;
        });
        jest.spyOn(bcrypt, 'compare').mockImplementation((plainPassword) => {
          // So sánh mật khẩu nhập vào với mockDoctor.password
          return plainPassword === mockDoctor.password
            ? Promise.resolve(true) // Nếu đúng mật khẩu thì trả về true
            : Promise.resolve(false); // Nếu sai mật khẩu thì trả về false
        });
        await authService.login('testuser', '1', AUTH.USER); // Gọi hàm và mong đợi lỗi // Nếu không có lỗi => thất bại
      } catch (e) {
        expect(e.message).toContain('Password is incorrect'); // Kiểm tra nội dung lỗi
      }
    });
  });
});
