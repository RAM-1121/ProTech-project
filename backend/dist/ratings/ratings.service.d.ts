export declare class RatingsService {
    private readonly ratings;
    submitRating(bookingId: string, rating: number, review: string): {
        id: string;
        bookingId: string;
        rating: number;
        review: string;
        createdAt: Date;
    };
    getRatings(): any[];
}
