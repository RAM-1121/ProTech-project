import { BookingsService } from './bookings.service';
export declare class BookingsController {
    private readonly bookingsService;
    constructor(bookingsService: BookingsService);
    create(bookingDto: any): any;
    findAll(): any[];
    findActive(): any[];
    findHistory(): any[];
    findOne(id: string): any;
    updateStatus(id: string, status: string): any;
    cancelBooking(id: string): any;
}
