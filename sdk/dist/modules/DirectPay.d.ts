import { BigNumber } from "ethers";
export interface DirectPayData {
    moduleName: "direct";
    type: "invoice" | "payment";
    creditor: string;
    debitor: string;
    notes?: string;
    file?: File;
    dueDate?: string;
}
export interface WriteDirectPayProps {
    currency: string;
    amount: number;
    ipfsHash?: string;
    imageUrl?: string;
    module: DirectPayData;
}
export declare function writeDirectPay({ module, amount, currency, imageUrl, ipfsHash, }: WriteDirectPayProps): Promise<{
    txHash: string;
    notaId: string;
}>;
export interface FundDirectPayProps {
    notaId: string;
    amount: BigNumber;
    tokenAddress: string;
}
export declare function fundDirectPay({ notaId, amount, tokenAddress, }: FundDirectPayProps): Promise<string>;
