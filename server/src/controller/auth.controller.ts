import { Controller, Post, Body, BadRequestException } from '@nestjs/common';
import { AuthService } from 'src/services/auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() body: { username: string; password: string }) {
    return this.authService.register(body.username, body.password);
  }
  
  @Post('login')
  async login(
    @Body() body: { username: string; password: string; role: string },
  ) {
    const { username, password, role } = body;
    console.log('Request Body:', body);
    // Kiểm tra role hợp lệ
    if (role !== 'user' && role !== 'doctor') {
      throw new BadRequestException('Invalid role');
    }

    return this.authService.login(username, password, role);
  }
  @Post('google')
  async loginWithGoogle(@Body() body: { username: string; email: string }) {
    return this.authService.loginWithGoogle(body.username, body.email);
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
