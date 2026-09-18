import { Controller, Get, Post, Body, UnauthorizedException } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Post('login')
  async login(@Body('mobile') mobile: string, @Body('role') role: string) {
    if (role === 'admin') {
      const masterAdmins = ['7731836976'];
      const assistantAdmins = ['9908090202', '6303798398'];
      
      if (masterAdmins.includes(mobile)) {
        return { token: 'mock-jwt-token-master-admin', user: { mobile, role: 'master_admin' } };
      } else if (assistantAdmins.includes(mobile)) {
        return { token: 'mock-jwt-token-assistant-admin', user: { mobile, role: 'assistant_admin' } };
      } else {
        throw new UnauthorizedException('Invalid admin mobile number');
      }
    }

    // Allow other roles to log in normally for now
    return {
      token: 'mock-jwt-token',
      user: { mobile, role },
    };
  }
}
