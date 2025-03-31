import { Controller, Post, Body, BadRequestException } from '@nestjs/common';
import { AuthService } from 'src/services/auth.service';
import { AUTH } from '../enums/auth.enum';
import { ApiResponse } from '../dto/responses/api-response.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // sửa lại ApiResponse
  @Post('register')
  async register(@Body() body: { username: string; password: string }) {
    var result = await this.authService.register(body.username, body.password);

    return new ApiResponse(201, 'Register successfully', result);
  }

  // sửa lại ApiResponse
  @Post('login')
  async login(
    @Body() body: { username: string; password: string; role: string },
  ) {
    const { username, password, role } = body;
    // console.log('Request Body:', body);
    // Kiểm tra role hợp lệ

    try {
      let result = await this.authService.login(username, password, role);
      return new ApiResponse(201, 'Login successfully', result);
    } catch (error) {
      throw new BadRequestException({
        statusCode: 400,
        message: error.message,
      });
    }
  }
  @Post('google')
  async loginWithGoogle(@Body() body: { username: string; email: string }) {
    return await this.authService.loginWithGoogle(body.username, body.email);
  }
  // @Post('refresh')
  // async refresh(@Body() body: { refreshToken: string }) {
  //    const user = await this.authService.validateRefreshToken(body.refreshToken);
  //    if (!user) {
  //       throw new Error('Invalid refresh token');
  //    }

  //    const newAccessToken = this.authService.generateAccessToken(user);
  //    return {
  //       access_token: newAccessToken,
  //    };
  // }
}
