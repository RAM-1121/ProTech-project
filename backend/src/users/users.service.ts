import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async updateLocation(userId: string, lat: number, lng: number): Promise<void> {
    await this.usersRepository.update(userId, {
      currentLocation: {
        type: 'Point',
        coordinates: [lng, lat], // GeoJSON is [longitude, latitude]
      },
    });
  }

  async findNearestExecutives(lat: number, lng: number, radiusMeters: number): Promise<User[]> {
    // For local SQLite testing, just return all executives since ST_DWithin is PostGIS specific
    return this.usersRepository.find({
      where: { role: UserRole.EXECUTIVE }
    });
  }
}
