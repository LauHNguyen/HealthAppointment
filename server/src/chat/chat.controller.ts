import { Controller, Get, Param } from '@nestjs/common';
import { ChatService } from './chat.service';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('messages/:userId/:partnerId')
  async getMessages(
    @Param('userId') userId: string,
    @Param('partnerId') partnerId: string,
  ) {
    return this.chatService.getMessages(userId, partnerId);
  }
}

