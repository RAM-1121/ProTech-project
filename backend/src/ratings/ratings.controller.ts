import { Controller, Post, Body, Get } from '@nestjs/common';
import { RatingsService } from './ratings.service';

@Controller('ratings')
export class RatingsController {
  constructor(private readonly ratingsService: RatingsService) {}

  @Post()
  submitRating(@Body() dto: { bookingId: string, rating: number, review: string }) {
    return this.ratingsService.submitRating(dto.bookingId, dto.rating, dto.review);
  }

  @Get()
  getRatings() {
    return this.ratingsService.getRatings();
  }
}
