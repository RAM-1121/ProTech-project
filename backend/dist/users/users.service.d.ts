import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
export declare class UsersService {
    private usersRepository;
    constructor(usersRepository: Repository<User>);
    updateLocation(userId: string, lat: number, lng: number): Promise<void>;
    findNearestExecutives(lat: number, lng: number, radiusMeters: number): Promise<User[]>;
}
