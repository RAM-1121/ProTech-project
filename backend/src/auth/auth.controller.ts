import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  async sendOtp(@Body('phone') phone: string) {
    const otp = await this.authService.generateOtp(phone);
    // In production, do not return the OTP. Send it via SMS/Twilio.
    return { message: 'OTP sent successfully (mocked: 123456)', otp };
  }

  @Post('verify-otp')
  async verifyOtp(@Body('phone') phone: string, @Body('otp') otp: string) {
    return this.authService.verifyOtp(phone, otp);
  }
}
