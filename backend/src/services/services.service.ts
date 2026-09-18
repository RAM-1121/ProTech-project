import { Injectable } from '@nestjs/common';

@Injectable()
export class ServicesService {
  getCatalog() {
    return [
      {
        id: 'ac_repair',
        name: 'AC Repair',
        description: 'Fix cooling issues, leaks, and general maintenance.',
        basePrice: 500,
      },
      {
        id: 'fridge_repair',
        name: 'Refrigerator Repair',
        description: 'Compressor issues, gas filling, thermostat replacement.',
        basePrice: 600,
      },
      {
        id: 'washing_machine_repair',
        name: 'Washing Machine Repair',
        description: 'Drum issues, water inlet/outlet fix, motor repair.',
        basePrice: 400,
      },
    ];
  }
}
