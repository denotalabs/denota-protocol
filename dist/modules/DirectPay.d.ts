import { BigNumber } from "ethers";
export interface DirectPayData {
    moduleName: "direct";
    type: "invoice" | "payment";
    creditor: string;
    debitor: string;
    notes?: string;
    file?: File;
    ipfsHash?: string;
    imageHash?: string;
    dueDate?: string;
}
export interface WriteDirectPayProps {
    currency: string;
    amount: number;
    module: DirectPayData;
}
export declare function writeDirectPay({ module, amount, currency, }: WriteDirectPayProps): Promise<string>;
export interface FundDirectPayProps {
    notaId: string;
    amount: BigNumber;
    tokenAddress: string;
}
export declare function fundDirectPay({ notaId, amount, tokenAddress, }: FundDirectPayProps): Promise<string>;
