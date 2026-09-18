export declare class WarrantiesService {
    private warranties;
    create(bookingId: string, item: string, expiryDate: Date): {
        id: string;
        bookingId: string;
        item: string;
        expiryDate: Date;
    };
    findAll(): any[];
}
