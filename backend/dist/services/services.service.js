"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ServicesService = void 0;
const common_1 = require("@nestjs/common");
let ServicesService = class ServicesService {
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
};
exports.ServicesService = ServicesService;
exports.ServicesService = ServicesService = __decorate([
    (0, common_1.Injectable)()
], ServicesService);
//# sourceMappingURL=services.service.js.map