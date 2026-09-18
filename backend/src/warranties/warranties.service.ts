import { Injectable } from '@nestjs/common';

@Injectable()
export class WarrantiesService {
  private warranties: any[] = [];

  create(bookingId: string, item: string, expiryDate: Date) {
    const warranty = { id: Date.now().toString(), bookingId, item, expiryDate };
    this.warranties.push(warranty);
    return warranty;
  }

  findAll() {
    return this.warranties;
  }
}
