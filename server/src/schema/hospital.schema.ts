import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Hospital extends Document {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true })
  address: string;

  @Prop({ required: true })
  district: string;

  @Prop()
  number: string;

  @Prop()
  specialty: string;
}

export const HospitalSchema = SchemaFactory.createForClass(Hospital);
