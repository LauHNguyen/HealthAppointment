import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Message, MessageDocument } from './message.schema';


@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Message.name) private messageModel: Model<MessageDocument>,
  ) {}

  async createMessage(messageData: {
    content: string;
    sender: string;
    receiver: string;
  }): Promise<Message> {
    const createdMessage = new this.messageModel(messageData);
    return createdMessage.save();
  }

  async getReceiverMessage(userId: string): Promise<Message[]>{
    return this.messageModel.find({sender: userId}).select('receiver sender').sort({createdAt :1}).exec();
  }

  async getMessages(userId: string, partnerId: string): Promise<Message[]> {
    return this.messageModel
      .find({
        $or: [
          { sender: userId, receiver: partnerId },
          { sender: partnerId, receiver: userId },
        ],
      })
      .sort({ createdAt: 1 })
      .exec();
  }
}

