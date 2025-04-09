import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import { User, UserDocument } from '../schema/user.schema';
import { Doctor, DoctorDocument } from '../schema/doctor.schema';
import { access } from 'fs';
import { AUTH } from '../enums/auth.enum';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Doctor.name) private doctorModel: Model<DoctorDocument>,
    private jwtService: JwtService,
  ) {} // {
  //    this.googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID); // Sử dụng Google Client ID từ biến môi trường
  // }

  // sửa lại thêm access token vào đăng ký
  async register(username: string, password: string) {
    if (!username) {
      throw new Error('Username is blank');
    }
    if (!password) {
      throw new Error('Password is blank');
    }
    if(username.length < 4 || username.length > 20) {
      throw new Error('Username must be between 4 and 20 characters long');
    }
    if (password.length < 8) {
      throw new Error('Password must be at least 8 characters long');
    }
    if (!/[A-Z]/.test(password)) {
      throw new Error('Password must contain at least one uppercase letter');
    }
    if (!/[a-z]/.test(password)) {
      throw new Error('Password must contain at least one lowercase letter');
    }
    if (!/[0-9]/.test(password)) {
      throw new Error('Password must contain at least one number');
    }
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      throw new Error('Password must contain at least one special character');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = await this.userModel.create({
      username,
      password: hashedPassword,
    });
    await newUser.save();
    const access_token = this.generateAccessToken(newUser);
    return {
      access_token,
      user: newUser,
    };
  }

  //sửa lại return access token
  async login(username: string, password: string, role: string) {
    let user;

    if (!username) {
      throw new Error('Username is blank');
    }

    if (!password) {
      throw new Error('Password is blank');
    }

    // Kiểm tra vai trò (user hay doctor)
    if (role === AUTH.USER) {
      user = await this.userModel.findOne({ username });
      if (!user) {
        throw new Error('Username is incorrect');
      }
    } else if (role === AUTH.DOCTOR) {
      let name = username;
      user = await this.doctorModel.findOne({ name });
      if (!user) {
        throw new Error('Username is incorrect');
      }
    } else {
      throw new Error('Invalid role');
    }
    // console.log('Found user:', user); // Test thông tin user có được lấy đúng không
    if (await bcrypt.compare(password, user.password)) {
      const accessToken = this.generateAccessToken(user);
      // console.log('Access token: ', accessToken); // Để lấy token khi test trên Postman
      const response = {
        access_token: accessToken,
      };
      return response;
    }
    throw new Error('Password is incorrect');
  }

  async loginWithGoogle(username: string, email: string) {
    // Kiểm tra user trong database
    let user = await this.userModel.findOne({ email });

    if (!user) {
      // Nếu user chưa tồn tại, tạo mới
      const hashedPassword = await bcrypt.hash(email, 10);
      user = new this.userModel({
        username: username, // Tên từ Google
        password: hashedPassword,
        email: email,
        authProvider: 'google', // Đánh dấu user đăng nhập bằng Google
      });
      await user.save();
    }

    // Tạo Access Token
    const accessToken = this.generateAccessToken(user);
    return {
      access_token: accessToken,
      user,
    };
  }

  generateAccessToken(user: UserDocument | DoctorDocument) {
    const payload = {
      username: 'username' in user ? user.username : user.name,
      role: user.role,
    };
    return this.jwtService.sign(payload, {
      secret: process.env.SECRETKEY,
      expiresIn: '30d',
    });
  }
}
