export declare class AuthService {
    private otpStore;
    generateOtp(phone: string): Promise<string>;
    verifyOtp(phone: string, otp: string): Promise<{
        success: boolean;
        token?: string;
    }>;
}
