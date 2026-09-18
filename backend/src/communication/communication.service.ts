import { Injectable } from '@nestjs/common';
import { AccessToken } from 'livekit-server-sdk';

@Injectable()
export class CommunicationService {
  async createLiveKitToken(roomName: string, participantName: string): Promise<string> {
    // In production, use env variables for API key and secret
    const apiKey = process.env.LIVEKIT_API_KEY || 'devkey';
    const apiSecret = process.env.LIVEKIT_API_SECRET || 'secret';
    
    const at = new AccessToken(apiKey, apiSecret, {
      identity: participantName,
    });
    at.addGrant({ roomJoin: true, room: roomName });
    return await at.toJwt();
  }
}
