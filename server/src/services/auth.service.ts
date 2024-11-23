import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { User, UserDocument } from 'src/schema/user.schema';
@Injectable()
export class AuthService {
   constructor(
      @InjectModel(User.name) private userModel: Model<UserDocument>,
      private jwtService: JwtService,
   ) {}

   async register(username: string, password: string) {
      const hashedPassword = await bcrypt.hash(password, 10);
      const newUser = new this.userModel({
         username,
         password: hashedPassword,
      });
      return newUser.save();
   }
   async login(username: string, password: string) {
      const user = await this.userModel.findOne({ username });
      console.log('Found user:', user);// test thông tin user có được lấy đúng không
      if (user && (await bcrypt.compare(password, user.password))) {
         const accessToken = this.generateAccessToken(user);
         console.log('Access token: ',accessToken);// để lấy token khi test trên postman
         // const refreshToken = this.generateRefreshToken(user);

         return {
            access_token: accessToken,
            //refresh_token: refreshToken,
         };
      }
      throw new Error('Invalid credentials');
   }

   generateAccessToken(user: UserDocument) {
      const payload = { username: user.username };
      return this.jwtService.sign(payload, { secret: process.env.SECRETKEY, expiresIn: '30m' });
   }

   // generateRefreshToken(user: UserDocument) {
   //    const payload = { username: user.username };
   //    return this.jwtService.sign(payload, { secret: process.env.JWT_REFRESH_SECRET, expiresIn: '30d' });
   // }

   // // Phương thức để xác thực Refresh Token
   // async validateRefreshToken(token: string) {
   //    try {
   //       const payload = this.jwtService.verify(token, { secret: process.env.JWT_REFRESH_SECRET });
   //       return await this.userModel.findOne({ username: payload.username });
   //    } catch (error) {
   //       throw new Error('Invalid refresh token');
   //    }
   // }
}
