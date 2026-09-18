import { PaymentsService } from './payments.service';
export declare class PaymentsController {
    private readonly paymentsService;
    constructor(paymentsService: PaymentsService);
    calculateBill(dto: {
        basePrice: number;
        extraMaterials?: number;
    }): any;
    generateUpiLink(dto: {
        amount: number;
        transactionRef: string;
    }): {
        upiLink: string;
    };
}
