import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
   const app = await NestFactory.create(AppModule);
   app.enableCors({
      origin: (origin, callback) => {
         if (!origin || origin.startsWith(process.env.LOCALHOST)) {
            callback(null, true);
         } else {
            callback(new Error('Not allowed by CORS'));
         } 
      },
      methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
      credentials: true,
   });
   app.useGlobalPipes(new ValidationPipe({
      transform: true, // Tự động chuyển đổi DTO
      whitelist: true, // Loại bỏ các trường không định nghĩa trong DTO
      forbidNonWhitelisted: true, // Từ chối nếu có trường thừa
    }));
   await app.listen(3000, '0.0.0.0');
}
bootstrap();
