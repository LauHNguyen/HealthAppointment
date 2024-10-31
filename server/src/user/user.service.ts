import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../schema/user.schema';

@Injectable()
export class UserService {
   constructor(
      @InjectModel(User.name) private userModel: Model<UserDocument>,
   ) {}

   async findAll(): Promise<User[]> {
      return this.userModel.find().exec();
   }
   async findByUsername(username: string): Promise<User | null> {
      return this.userModel.findOne({ username }).exec();
   }

   async updateUser(userId: string, updateData: Partial<User>): Promise<User> {
      return this.userModel.findByIdAndUpdate(userId, updateData, { new: true }).select('_id __v password IsDelete');
   }

   calculateProfileCompletion(user: User): number {
      // Lấy danh sách các thuộc tính từ schema của User
      const userSchemaPaths = this.userModel.schema.paths;
        // Bỏ qua các thuộc tính không cần thiết như '_id', '__v', 'IsDelete', etc.
      const excludedFields = ['_id', '__v', 'IsDelete', 'username', 'password']; 
      const requiredFields = Object.keys(userSchemaPaths).filter(
        field => !excludedFields.includes(field)
      );
        // Đếm số thuộc tính đã được điền
      let filledFields = 0;
      for (const field of requiredFields) {
        if (user[field] !== null && user[field] !== undefined && user[field] !== '') {
          filledFields++;
        }
      }
        // Tính toán phần trăm hoàn thành
      const completionPercentage = (filledFields / requiredFields.length) * 100;
  
      return completionPercentage;
    }
    async findById(userId: string): Promise<User | null> {
      return this.userModel.findById(userId).exec();
    }

    async getUserProfile(userId: string): Promise<User> {
      return await this.userModel.findById(userId).select('-password -_id -__v');
    }
}
