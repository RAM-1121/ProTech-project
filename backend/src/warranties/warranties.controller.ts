import { Controller, Post, Body, Get } from '@nestjs/common';
import { WarrantiesService } from './warranties.service';

@Controller('warranties')
export class WarrantiesController {
  constructor(private readonly warrantiesService: WarrantiesService) {}

  @Post()
  create(@Body() dto: { bookingId: string, item: string, expiryDate: string }) {
    return this.warrantiesService.create(dto.bookingId, dto.item, new Date(dto.expiryDate));
  }

  @Get()
  findAll() {
    return this.warrantiesService.findAll();
  }
}
