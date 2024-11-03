import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { MongooseModule } from '@nestjs/mongoose';
import { UserModule } from './models/user.module';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './models/auth.module';
import { HospitalModule } from './models/hospital.module';

@Module({
  imports: [
    ConfigModule.forRoot(), //đọc thông tin từ file .env
    MongooseModule.forRoot(process.env.DATABASE),
    AuthModule,
    UserModule,
    HospitalModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
