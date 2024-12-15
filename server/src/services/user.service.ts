import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../schema/user.schema';

@Injectable()
export class UserService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  async findAll(): Promise<User[]> {
    return this.userModel.find().exec();
  }


  async findByUsername(username: string): Promise<User | null> {
    return this.userModel.findOne({ username }).exec();
  }
   async getUserName(userId: string) : Promise<User>{
       const username = await this.userModel.findById(userId).select('username');
       console.log(username);
       return username; 
      // return await this.userModel.findById(userId).select('username');
   }

   //cho đăng nhập google
   async findByEmail(email: string): Promise<User | null> {
      return this.userModel.findOne({ email }).exec();
    }
  
    async create(userData: Partial<User>): Promise<User> {
      const newUser = new this.userModel(userData);
      return newUser.save();
    }


   async updateUser(userId: string, updateData: Partial<User>): Promise<User> {
      return this.userModel.findByIdAndUpdate(userId, updateData, { new: true }).select('_id __v password IsDelete');
   }


  async updateUser(userId: string, updateData: Partial<User>): Promise<User> {
    return this.userModel
      .findByIdAndUpdate(userId, updateData, { new: true })
      .select('_id __v password IsDelete');
  }

  async getUserProfile(userId: string): Promise<User> {
    return await this.userModel.findById(userId).select('-password -_id -__v');
  }
}
