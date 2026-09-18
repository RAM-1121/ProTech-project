import { Injectable } from '@nestjs/common';

@Injectable()
export class PaymentsService {
  calculateBill(basePrice: number, extraMaterials: number = 0): any {
    const subtotal = basePrice + extraMaterials;
    const taxes = subtotal * 0.18; // 18% GST
    const total = subtotal + taxes;

    return {
      basePrice,
      extraMaterials,
      subtotal,
      taxes,
      total,
    };
  }

  generateUpiLink(payeeVpa: string, payeeName: string, amount: number, transactionRef: string): string {
    const url = new URL('upi://pay');
    url.searchParams.append('pa', payeeVpa);
    url.searchParams.append('pn', payeeName);
    url.searchParams.append('tr', transactionRef);
    url.searchParams.append('am', amount.toFixed(2));
    url.searchParams.append('cu', 'INR');
    
    return url.toString();
  }
}
