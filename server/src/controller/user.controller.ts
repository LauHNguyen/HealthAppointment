import {
  Body,
  Controller,
  Get,
  Param,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';
import { User } from '../schema/user.schema';

import { JwtAuthGuard } from 'src/configuration/jwt-auth.guard';
import { Request } from 'express';
import { UserService } from 'src/services/user.service';

@Controller('user')
@UseGuards(JwtAuthGuard)
export class UserController {
  constructor(private readonly userService: UserService) {}

  // For Admin
  @Get()
  async getAllUsers(): Promise<User[]> {
    return this.userService.findAll();
  }
  //    @Get('id')
  //    async getCurrentUserId(@Req() req: Request) {
  //     // Lấy user từ request đã được giải mã thông qua JWT Guard
  //     const user: any = req.user; // user đã được xác thực
  //     return { userId: user.id }; // Trả về ID người dùng
  // }

  //    // Update
  //    @Put('update')
  //    async updateUser(@Req() req: Request,@Body() updateData: Partial<User>){
  //     // Lấy userId từ token đã xác thực
  //     const userId = req.user['id'];

  //     // Gọi service để cập nhật thông tin
  //     return this.userService.updateUser(userId, updateData);
  //    }

  //    @Get('profile')
  //   async getProfile(@Req() req: Request) {
  //     // Lấy user từ request đã được giải mã thông qua JWT Guard
  //     const user: any = req.user;
  //     //const userId = user._id;
  //     return await this.userService.getUserProfile(user.id);
  //   }
}
