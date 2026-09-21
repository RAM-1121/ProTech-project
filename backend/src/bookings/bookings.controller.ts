import { Controller, Get, Post, Body, Param, Patch, Delete, Query } from '@nestjs/common';
import { BookingsService } from './bookings.service';

@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  create(@Body() bookingDto: any) {
    return this.bookingsService.create(bookingDto);
  }

  @Get()
  findAll(@Query('customerMobile') customerMobile?: string) {
    return this.bookingsService.findAll(customerMobile);
  }

  @Get('active')
  findActive() {
    return this.bookingsService.findActive();
  }

  @Get('history')
  findHistory() {
    return this.bookingsService.findHistory();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.bookingsService.findOne(id);
  }

  @Patch(':id/status')
  updateStatus(
    @Param('id') id: string, 
    @Body('status') status: string,
    @Body('assignedEmployee') assignedEmployee?: any
  ) {
    return this.bookingsService.updateStatus(id, status, assignedEmployee);
  }

  @Post(':id/cancel')
  cancelBooking(@Param('id') id: string) {
    return this.bookingsService.cancelBooking(id);
  }

  @Delete('completed')
  deleteCompletedBookings() {
    return this.bookingsService.clearCompletedBookings();
  }

  @Delete(':id')
  deleteBooking(@Param('id') id: string) {
    return this.bookingsService.deleteBooking(id);
  }

  @Patch(':id/rating')
  updateRating(
    @Param('id') id: string,
    @Body('rating') rating: number
  ) {
    return this.bookingsService.updateRating(id, rating);
  }
}
