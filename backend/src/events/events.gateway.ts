import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UsersService } from '../users/users.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly usersService: UsersService) {}

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('locationUpdate')
  async handleLocationUpdate(@MessageBody() data: { userId: string; lat: number; lng: number }, @ConnectedSocket() client: Socket) {
    console.log(`Location update from ${client.id} for user ${data.userId}:`, data);
    
    // Save to database using PostGIS
    if (data.userId && data.lat && data.lng) {
      await this.usersService.updateLocation(data.userId, data.lat, data.lng);
    }
    
    // Broadcast back to customers
    this.server.emit('locationUpdated', {
      clientId: client.id,
      userId: data.userId,
      lat: data.lat,
      lng: data.lng,
    });
  }

  @SubscribeMessage('statusUpdate')
  handleStatusUpdate(@MessageBody() data: any, @ConnectedSocket() client: Socket) {
    console.log(`Status update from ${client.id}:`, data);
    
    // Broadcast status change (e.g., Arrived, Diagnosing, Repairing, Completed)
    this.server.emit('statusUpdated', {
      clientId: client.id,
      status: data.status,
    });
  }
}
