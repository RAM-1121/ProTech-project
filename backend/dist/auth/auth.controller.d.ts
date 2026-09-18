import { AuthService } from './auth.service';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    sendOtp(phone: string): Promise<{
        message: string;
        otp: string;
    }>;
    verifyOtp(phone: string, otp: string): Promise<{
        success: boolean;
        token?: string;
    }>;
}
