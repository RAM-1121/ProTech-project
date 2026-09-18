import { ServicesService } from './services.service';
export declare class ServicesController {
    private readonly servicesService;
    constructor(servicesService: ServicesService);
    getCatalog(): {
        id: string;
        name: string;
        description: string;
        basePrice: number;
    }[];
}
