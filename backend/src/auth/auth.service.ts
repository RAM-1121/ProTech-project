import { Injectable } from '@nestjs/common';

@Injectable()
export class AuthService {
  private otpStore = new Map<string, string>();

  async generateOtp(phone: string): Promise<string> {
    const otp = '123456'; // Mocked static OTP for development
    this.otpStore.set(phone, otp);
    return otp;
  }

  async verifyOtp(phone: string, otp: string): Promise<{ success: boolean, token?: string }> {
    const storedOtp = this.otpStore.get(phone);
    if (storedOtp === otp) {
      this.otpStore.delete(phone);
      return { success: true, token: 'mock-jwt-token-customer' };
    }
    return { success: false };
  }
}
