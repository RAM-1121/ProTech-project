import { Injectable } from '@nestjs/common';

@Injectable()
export class BookingsService {
  private readonly bookings: any[] = [];

  create(bookingDto: any) {
    const newBooking = { id: Date.now().toString(), ...bookingDto, status: 'pending' };
    this.bookings.push(newBooking);
    return newBooking;
  }

  findAll() {
    return this.bookings;
  }

  findActive() {
    return this.bookings.filter(b => ['pending', 'assigned', 'diagnosing', 'repairing'].includes(b.status));
  }

  findHistory() {
    return this.bookings.filter(b => ['completed', 'cancelled'].includes(b.status));
  }

  findOne(id: string) {
    return this.bookings.find(b => b.id === id);
  }

  updateStatus(id: string, status: string) {
    const booking = this.findOne(id);
    if (booking) {
      booking.status = status;
    }
    return booking;
  }

  cancelBooking(id: string) {
    return this.updateStatus(id, 'cancelled');
  }
}
