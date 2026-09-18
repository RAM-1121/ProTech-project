"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsService = void 0;
const common_1 = require("@nestjs/common");
let PaymentsService = class PaymentsService {
    calculateBill(basePrice, extraMaterials = 0) {
        const subtotal = basePrice + extraMaterials;
        const taxes = subtotal * 0.18;
        const total = subtotal + taxes;
        return {
            basePrice,
            extraMaterials,
            subtotal,
            taxes,
            total,
        };
    }
    generateUpiLink(payeeVpa, payeeName, amount, transactionRef) {
        const url = new URL('upi://pay');
        url.searchParams.append('pa', payeeVpa);
        url.searchParams.append('pn', payeeName);
        url.searchParams.append('tr', transactionRef);
        url.searchParams.append('am', amount.toFixed(2));
        url.searchParams.append('cu', 'INR');
        return url.toString();
    }
};
exports.PaymentsService = PaymentsService;
exports.PaymentsService = PaymentsService = __decorate([
    (0, common_1.Injectable)()
], PaymentsService);
//# sourceMappingURL=payments.service.js.map