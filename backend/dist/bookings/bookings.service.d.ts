export declare class BookingsService {
    private readonly bookings;
    create(bookingDto: any): any;
    findAll(): any[];
    findActive(): any[];
    findHistory(): any[];
    findOne(id: string): any;
    updateStatus(id: string, status: string): any;
    cancelBooking(id: string): any;
}
