import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';

import { User, UserSchema } from 'src/schema/user.schema';
import { UserService } from 'src/services/user.service';
import { JwtStrategy } from 'src/configuration/jwt.strategy';
import { AuthService } from 'src/services/auth.service';
import { AuthController } from 'src/controller/auth.controller';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
    JwtModule.register({
      secret: process.env.SECRETKEY, //'H3al5hA00985M3ntNg763n0h75a6',
      signOptions: { expiresIn: '30m' },
    }),
  ],
  providers: [AuthService, JwtStrategy, UserService],
  controllers: [AuthController],
})
export class AuthModule {}
