import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import { User, UserDocument } from 'src/schema/user.schema';
import { Doctor, DoctorDocument } from 'src/schema/doctor.schema';

@Injectable()
export class AuthService {
   private googleClient: OAuth2Client;

   constructor(
      @InjectModel(User.name) private userModel: Model<UserDocument>,
      @InjectModel(Doctor.name) private doctorModel: Model<DoctorDocument>,
      private jwtService: JwtService,
    ){}// {
   //    this.googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID); // Sử dụng Google Client ID từ biến môi trường
   // }

   async register(username: string, password: string) {
      const user = await this.userModel.findOne({username});
      console.log(user);
      if(user == null){
         const hashedPassword = await bcrypt.hash(password, 10);
         const newUser = new this.userModel({
            username,
            password: hashedPassword,
         });
         return newUser.save();
      } 
      else
         throw new Error('User existed'); 
   }

   async login(username: string, password: string, role: string) {
      let user;

   // Kiểm tra vai trò (user hay doctor)
   if (role === 'user') {
      user = await this.userModel.findOne({ username });
      if(!user) {
         throw new Error('User not found');
      }
   } else if (role === 'doctor') {
      let name = username;
      user = await this.doctorModel.findOne({ name });
      if(!user) {
         throw new Error('Doctor not found');
      }
   } else {
      throw new Error('Invalid role');
   }
      console.log('Found user:', user); // Test thông tin user có được lấy đúng không
      if (user && (await bcrypt.compare(password, user.password))) {
         const accessToken = this.generateAccessToken(user);
         
         return {
            access_token: accessToken,
         };
         console.log('Access token: ', accessToken); // Để lấy token khi test trên Postman
      }
      else
         throw new Error('Invalid credentials');
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
         //user,
      };
   }

   generateAccessToken(user: UserDocument | DoctorDocument) {
      const payload = { username: 'username' in user ? user.username : user.name, role: user.role  };
      return this.jwtService.sign(payload, { secret: process.env.SECRETKEY, expiresIn: '30m' });
   }
}
