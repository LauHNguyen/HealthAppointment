import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

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
   await app.listen(3000, '0.0.0.0');
}
bootstrap();
