import { Injectable } from '@nestjs/common';
import { calendar_v3 } from '@googleapis/calendar';
import { google } from 'googleapis';
import { Appointment } from '../schema/appointment.schema';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from '../schema/user.schema';
import { Doctor, DoctorDocument } from '../schema/doctor.schema';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class GoogleCalendarService {
  private calendar: calendar_v3.Calendar;
  private readonly calendarId = '';

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(Doctor.name) private doctorModel: Model<DoctorDocument>,
  ) {
    const auth = new google.auth.GoogleAuth({
      keyFile: path.join(process.cwd(), ''),
      scopes: ['https://www.googleapis.com/auth/calendar'],
    });
    this.calendar = google.calendar({ version: 'v3', auth });
  }

  async createEvent(appointment: Appointment): Promise<string> {
    try {
      // Query user và doctor
      const user = await this.userModel
        .findById(appointment.user['_id'] || appointment.user)
        .select('name email')
        .exec();
      const doctor = await this.doctorModel
        .findById(appointment.doctor['_id'] || appointment.doctor)
        .select('name')
        .exec();

      const username = user?.name || 'Unknown User';
      const doctorname = doctor?.name || 'Unknown Doctor';
      const userEmail = user?.email || 'no-email@demo.com';

      // Log input
      console.log('Appointment input:', {
        appointmentDate: appointment.appointmentDate,
        appointmentTime: appointment.appointmentTime,
        userId: appointment.user,
        doctorId: appointment.doctor,
        hospitalName: appointment.hospitalName,
      });

      // Parse appointmentDate
      let formattedDate: string;
      if (typeof appointment.appointmentDate === 'string') {
        const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
        if (dateRegex.test(appointment.appointmentDate)) {
          formattedDate = appointment.appointmentDate;
        } else {
          const parsedDate = new Date(appointment.appointmentDate);
          if (isNaN(parsedDate.getTime())) {
            throw new Error('Invalid appointmentDate format');
          }
          formattedDate = parsedDate.toISOString().split('T')[0];
        }
      } else if (appointment.appointmentDate instanceof Date) {
        formattedDate = appointment.appointmentDate.toISOString().split('T')[0];
      } else {
        throw new Error('Invalid appointmentDate type');
      }

      console.log('Formatted appointmentDate:', formattedDate);

      // Kiểm tra appointmentTime format
      const timeRegex = /^\d{1,2}:\d{2}\s*-\s*\d{1,2}:\d{2}$/;
      if (!timeRegex.test(appointment.appointmentTime)) {
        throw new Error(
          'Invalid appointmentTime format, expected H:mm - H:mm or HH:mm - HH:mm',
        );
      }

      // Parse appointmentTime
      const [startTimeRaw, endTimeRaw] = appointment.appointmentTime
        .split('-')
        .map((t) => t.trim());
      const startTime = startTimeRaw.padStart(5, '0');
      const endTime = endTimeRaw.padStart(5, '0');

      console.log('Parsed time:', {
        startTimeRaw,
        endTimeRaw,
        startTime,
        endTime,
      });

      // Tạo start và end Date
      const startDateTime = new Date(`${formattedDate}T${startTime}:00+07:00`);
      const endDateTime = new Date(`${formattedDate}T${endTime}:00+07:00`);

      // Kiểm tra Date hợp lệ
      if (isNaN(startDateTime.getTime()) || isNaN(endDateTime.getTime())) {
        console.log('Invalid Date objects:', {
          startDateTime: startDateTime.toString(),
          endDateTime: endDateTime.toString(),
        });
        throw new Error('Invalid date or time values');
      }

      console.log('Date objects:', {
        startDateTime: startDateTime.toISOString(),
        endDateTime: endDateTime.toISOString(),
      });

      const event: calendar_v3.Schema$Event = {
        summary: `Lịch hẹn với ${doctorname}`,
        location: appointment.hospitalName,
        description: `Bệnh nhân: ${username}`,
        start: {
          dateTime: startDateTime.toISOString(),
          timeZone: 'Asia/Ho_Chi_Minh',
        },
        end: {
          dateTime: endDateTime.toISOString(),
          timeZone: 'Asia/Ho_Chi_Minh',
        },
        // Bỏ attendees để tránh lỗi DWD
      };

      console.log('Event to create:', event);

      const response = await this.calendar.events.insert({
        calendarId: this.calendarId,
        requestBody: event,
      });

      console.log('Event created:', response.data);

      return response.data.id;
    } catch (error) {
      console.error('Error creating Google Calendar event:', error);
      throw new Error(`Failed to create event: ${error.message}`);
    }
  }

  async deleteEvent(eventId: string): Promise<void> {
    await this.calendar.events.delete({
      calendarId: this.calendarId,
      eventId,
    });
  }
}
