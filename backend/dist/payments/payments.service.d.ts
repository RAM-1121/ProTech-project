export declare class PaymentsService {
    calculateBill(basePrice: number, extraMaterials?: number): any;
    generateUpiLink(payeeVpa: string, payeeName: string, amount: number, transactionRef: string): string;
}
