import { Injectable } from '@nestjs/common';

@Injectable()
export class RatingsService {
  private readonly ratings: any[] = [];

  submitRating(bookingId: string, rating: number, review: string) {
    const newRating = {
      id: Date.now().toString(),
      bookingId,
      rating,
      review,
      createdAt: new Date(),
    };
    this.ratings.push(newRating);
    return newRating;
  }

  getRatings() {
    return this.ratings;
  }
}
