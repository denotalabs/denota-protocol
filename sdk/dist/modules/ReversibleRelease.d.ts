import { BigNumber } from "ethers";
export interface ReversibleReleaseData {
    moduleName: "reversibleRelease";
    type: "invoice" | "payment";
    creditor: string;
    debitor: string;
    inspector?: string;
}
export interface WriteReversibleReleaseyProps {
    currency: string;
    amount: number;
    ipfsHash?: string;
    imageUrl?: string;
    module: ReversibleReleaseData;
}
export declare function writeReversibleRelease({ module, amount, currency, imageUrl, ipfsHash, }: WriteReversibleReleaseyProps): Promise<{
    txHash: string;
    notaId: string;
}>;
export interface FundReversibleReleaseyProps {
    notaId: string;
    amount: BigNumber;
    tokenAddress: string;
}
export declare function fundReversibleRelease({ notaId, amount, tokenAddress, }: FundReversibleReleaseyProps): Promise<string>;
export interface CashReversibleReleaseyProps {
    creditor: string;
    debtor: string;
    notaId: string;
    amount: BigNumber;
    type: "reversal" | "release";
}
export declare function cashReversibleRelease({ creditor, debtor, notaId, type, amount, }: CashReversibleReleaseyProps): Promise<string>;
