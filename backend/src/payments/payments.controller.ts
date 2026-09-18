import { Controller, Post, Body } from '@nestjs/common';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('calculate')
  calculateBill(@Body() dto: { basePrice: number, extraMaterials?: number }) {
    return this.paymentsService.calculateBill(dto.basePrice, dto.extraMaterials);
  }

  @Post('upi-link')
  generateUpiLink(@Body() dto: { amount: number, transactionRef: string }) {
    const upiLink = this.paymentsService.generateUpiLink(
      'merchant@upi',
      'ApplianceService',
      dto.amount,
      dto.transactionRef
    );
    return { upiLink };
  }
}
