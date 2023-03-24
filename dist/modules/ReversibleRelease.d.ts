import { BigNumber } from "ethers";
export interface ReversibleReleaseData {
    moduleName: "reversibleRelease";
    type: "invoice" | "payment";
    creditor: string;
    debitor: string;
    inspector?: string;
    notes?: string;
    file?: File;
    ipfsHash?: string;
    imageHash?: string;
}
export interface WriteReversibleReleaseyProps {
    currency: string;
    amount: number;
    module: ReversibleReleaseData;
}
export declare function writeReversiblePay({ module, amount, currency, }: WriteReversibleReleaseyProps): Promise<string>;
export interface CashReversibleReleaseyProps {
    creditor: string;
    debtor: string;
    cheqId: string;
    amount: BigNumber;
    type: "reversal" | "release";
}
export declare function cashReversiblePay({ creditor, debtor, cheqId, type, amount, }: CashReversibleReleaseyProps): Promise<string>;
