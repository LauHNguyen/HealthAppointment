import {
   WebSocketGateway,
   SubscribeMessage,
   MessageBody,
   WebSocketServer,
   ConnectedSocket,
 } from '@nestjs/websockets';
 import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';

 
 @WebSocketGateway({
   cors: {
     origin: '*',
   },
 })
 export class ChatGateway {
   @WebSocketServer() server: Server;
 
   constructor(private readonly chatService: ChatService) {}
 
   @SubscribeMessage('sendMessage')
   async handleMessage(
     @MessageBody() data: { content: string; sender: string; receiver: string },
     @ConnectedSocket() client: Socket,
   ) {
     const message = await this.chatService.createMessage(data);
     this.server.emit('newMessage', message);
     return message;
   }
 
   @SubscribeMessage('joinRoom')
   handleJoinRoom(
     @MessageBody() room: string,
     @ConnectedSocket() client: Socket,
   ) {
     client.join(room);
     return { status: 'joined' };
   }
 
   @SubscribeMessage('leaveRoom')
   handleLeaveRoom(
     @MessageBody() room: string,
     @ConnectedSocket() client: Socket,
   ) {
     client.leave(room);
     return { status: 'left' };
   }
 }
 
 