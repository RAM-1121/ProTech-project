"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BookingsService = void 0;
const common_1 = require("@nestjs/common");
let BookingsService = class BookingsService {
    bookings = [];
    create(bookingDto) {
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
    findOne(id) {
        return this.bookings.find(b => b.id === id);
    }
    updateStatus(id, status) {
        const booking = this.findOne(id);
        if (booking) {
            booking.status = status;
        }
        return booking;
    }
    cancelBooking(id) {
        return this.updateStatus(id, 'cancelled');
    }
};
exports.BookingsService = BookingsService;
exports.BookingsService = BookingsService = __decorate([
    (0, common_1.Injectable)()
], BookingsService);
//# sourceMappingURL=bookings.service.js.map