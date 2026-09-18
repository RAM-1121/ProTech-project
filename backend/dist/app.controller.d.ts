import { AppService } from './app.service';
export declare class AppController {
    private readonly appService;
    constructor(appService: AppService);
    getHello(): string;
    login(mobile: string, role: string): Promise<{
        token: string;
        user: {
            mobile: string;
            role: string;
        };
    }>;
}
