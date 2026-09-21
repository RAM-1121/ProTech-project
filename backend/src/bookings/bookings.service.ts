import { Injectable } from '@nestjs/common';
import { NotificationsGateway } from '../notifications/notifications.gateway';

@Injectable()
export class BookingsService {
  private readonly bookings: any[] = [];

  constructor(private readonly notificationsGateway: NotificationsGateway) {}

  create(bookingDto: any) {
    const id = bookingDto.orderId || Date.now().toString();
    const newBooking = { id, ...bookingDto, status: 'Pending' };
    this.bookings.push(newBooking);
    this.notificationsGateway.broadcast('update_received', { type: 'NEW_WORK_ORDER', data: newBooking });
    return newBooking;
  }

  findAll(customerMobile?: string) {
    if (customerMobile) {
      return this.bookings.filter(b => b.customerMobile === customerMobile);
    }
    return this.bookings;
  }

  findActive() {
    return this.bookings.filter(b => ['Pending', 'Assigned', 'diagnosing', 'repairing', 'EXECUTIVE_PENDING', 'executive_pending', 'Payment Pending'].includes(b.status));
  }

  findHistory() {
    return this.bookings.filter(b => ['Completed', 'cancelled'].includes(b.status));
  }

  findOne(id: string) {
    return this.bookings.find(b => b.id === id);
  }

  updateStatus(id: string, status: string, assignedEmployee?: any, pendingReason?: string) {
    const booking = this.findOne(id);
    if (booking) {
      booking.status = status;
      if (assignedEmployee) {
        booking.assignedEmployee = assignedEmployee;
      }
      if (pendingReason !== undefined) {
        booking.pendingReason = pendingReason;
      }
      this.notificationsGateway.broadcast('update_received', { type: 'STATUS_UPDATE', data: booking });
    }
    return booking;
  }

  cancelBooking(id: string) {
    return this.updateStatus(id, 'cancelled');
  }

  deleteBooking(id: string) {
    const booking = this.findOne(id);
    if (booking) {
      booking.status = 'Deleted By ADMIN';
      this.notificationsGateway.broadcast('update_received', { type: 'DELETE_WORK_ORDER', data: booking });
    }
    return booking;
  }

  clearCompletedBookings() {
    let clearedCount = 0;
    for (let i = this.bookings.length - 1; i >= 0; i--) {
      const status = (this.bookings[i].status || '').toLowerCase();
      if (status === 'completed' || status === 'complaint closed thank you for choosing protech cooling solutions') {
        if (!this.bookings[i].hiddenFromAdmin) {
          this.bookings[i].hiddenFromAdmin = true;
          clearedCount++;
        }
      }
    }
    // Broadcast an event to trigger a refresh for clients if needed
    this.notificationsGateway.broadcast('update_received', { type: 'ADMIN_CLEAR_COMPLETED' });
    return { cleared: clearedCount };
  }

  updateRating(id: string, rating: number) {
    const booking = this.findOne(id);
    if (booking) {
      booking.rating = rating;
      this.notificationsGateway.broadcast('update_received', { type: 'RATING_UPDATE', data: booking });
    }
    return booking;
  }
}
