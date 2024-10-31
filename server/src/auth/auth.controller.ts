import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
   constructor(private readonly authService: AuthService) {}

   @Post('register')
   async register(@Body() body: { username: string; password: string }) {
      return this.authService.register(body.username, body.password);
   }
   @Post('login')
   async login(@Body() body: { username: string; password: string }) {
      return this.authService.login(body.username, body.password);
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
