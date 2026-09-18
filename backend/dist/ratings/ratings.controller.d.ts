import { RatingsService } from './ratings.service';
export declare class RatingsController {
    private readonly ratingsService;
    constructor(ratingsService: RatingsService);
    submitRating(dto: {
        bookingId: string;
        rating: number;
        review: string;
    }): {
        id: string;
        bookingId: string;
        rating: number;
        review: string;
        createdAt: Date;
    };
    getRatings(): any[];
}
