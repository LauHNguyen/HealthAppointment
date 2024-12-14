import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema()
export class User {
   @Prop({ required: true })
   username: string;

   @Prop({ required: true })
   password: string;

   @Prop()
   email: string;

   @Prop()
   birthOfDate: Date;

   @Prop()
   gender: string; 

   @Prop({ default: 'local' }) // 'local' hoặc 'google'
   authProvider: string;

   @Prop({required: true, default: 'user'})
   role: string
}

export const UserSchema = SchemaFactory.createForClass(User);
