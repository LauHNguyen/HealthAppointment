import { Injectable } from '@nestjs/common';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { UserService } from 'src/services/user.service';
import { DoctorService } from 'src/services/doctor.service';
import { User } from 'src/schema/user.schema';
import { Doctor } from 'src/schema/doctor.schema';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private usersService: UserService, private doctorService: DoctorService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.SECRETKEY,
    });
  }

  async validate(payload: any): Promise<User | Doctor> {
    const { username, role } = payload;

  // Kiểm tra role để xác định tìm user hay doctor
  if (role === 'user') {
    const user = await this.usersService.findByUsername(username);
    if (!user) {
      throw new Error('User not found');
    }
    return user; // Trả về User
  } else if (role === 'doctor') {
    let name = username;
    const doctor = await this.doctorService.findByDoctorname(name);
    if (!doctor) {
      throw new Error('Doctor not found');
    }
    return doctor; // Trả về Doctor
  } else {
    throw new Error('Invalid role');
  }
  }
}
