import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type DoctorDocument = Doctor & Document;

@Schema()
export class Doctor {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  specialty: string;

  @Prop({ required: true })
  hospitalName: string;

  @Prop({ type: String, default:"6:00"})
  startTime: string; 

  @Prop({ type: String, default:"18:00"})
  endTime: string; 

  @Prop({ type: [String], default:["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]})
  workingDays: string[]; 
}

export const DoctorSchema = SchemaFactory.createForClass(Doctor);