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
export declare function writeReversibleRelease({ module, amount, currency, }: WriteReversibleReleaseyProps): Promise<string>;
export interface FundReversibleReleaseyProps {
    cheqId: string;
    amount: BigNumber;
    tokenAddress: string;
}
export declare function fundReversibleRelease({ cheqId, amount, tokenAddress, }: FundReversibleReleaseyProps): Promise<string>;
export interface CashReversibleReleaseyProps {
    creditor: string;
    debtor: string;
    cheqId: string;
    amount: BigNumber;
    type: "reversal" | "release";
}
export declare function cashReversibleRelease({ creditor, debtor, cheqId, type, amount, }: CashReversibleReleaseyProps): Promise<string>;
