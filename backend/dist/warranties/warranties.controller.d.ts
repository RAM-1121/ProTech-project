import { WarrantiesService } from './warranties.service';
export declare class WarrantiesController {
    private readonly warrantiesService;
    constructor(warrantiesService: WarrantiesService);
    create(dto: {
        bookingId: string;
        item: string;
        expiryDate: string;
    }): {
        id: string;
        bookingId: string;
        item: string;
        expiryDate: Date;
    };
    findAll(): any[];
}
