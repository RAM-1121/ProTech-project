import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UsersService } from '../users/users.service';
export declare class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
    private readonly usersService;
    server: Server;
    constructor(usersService: UsersService);
    handleConnection(client: Socket): void;
    handleDisconnect(client: Socket): void;
    handleLocationUpdate(data: {
        userId: string;
        lat: number;
        lng: number;
    }, client: Socket): Promise<void>;
    handleStatusUpdate(data: any, client: Socket): void;
}
