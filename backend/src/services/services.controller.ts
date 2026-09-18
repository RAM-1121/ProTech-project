import { Controller, Get } from '@nestjs/common';
import { ServicesService } from './services.service';

@Controller('services')
export class ServicesController {
  constructor(private readonly servicesService: ServicesService) {}

  @Get('catalog')
  getCatalog() {
    return this.servicesService.getCatalog();
  }
}
