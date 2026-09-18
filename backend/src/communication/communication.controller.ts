import { Controller, Get, Query } from '@nestjs/common';
import { CommunicationService } from './communication.service';

@Controller('communication')
export class CommunicationController {
  constructor(private readonly communicationService: CommunicationService) {}

  @Get('livekit/token')
  async getLiveKitToken(@Query('room') room: string, @Query('participant') participant: string) {
    const token = await this.communicationService.createLiveKitToken(room, participant);
    return { token };
  }
}
