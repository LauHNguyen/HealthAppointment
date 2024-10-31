import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { User, UserSchema } from 'src/schema/user.schema';
import { UserService } from 'src/user/user.service';
import { JwtStrategy } from 'src/configuration/jwt.strategy';


@Module({
   imports: [
      MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
      JwtModule.register({
         secret: process.env.SECRETKEY,//'H3al5hA00985M3ntNg763n0h75a6',
         signOptions: { expiresIn: '30m' },
      }),
   ],
   providers: [AuthService,JwtStrategy, UserService,],
   controllers: [AuthController],
})
export class AuthModule {}
