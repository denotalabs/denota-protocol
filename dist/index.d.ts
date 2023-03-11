export declare const DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";
export declare const DENOTA_SUPPORTED_CHAIN_IDS: number[];
export declare function setProvider(web3Connection: any): Promise<void>;
interface ApproveTokenProps {
    currency: string;
    approvalAmount: number;
}
export declare function approveToken({ currency, approvalAmount, }: ApproveTokenProps): Promise<void>;
export interface DirectPayData {
    moduleName: "Direct";
    type: "invoice" | "payment";
    creditor: string;
    debitor: string;
    notes?: string;
    file?: File;
    ipfsHash?: string;
}
export interface EscrowData {
    moduleName: "Escrow";
    inspectionPeriod: number;
}
type ModuleData = DirectPayData | EscrowData;
export interface WriteProps {
    currency: string;
    amount: number;
    module: ModuleData;
}
export declare function write({ module, amount, currency }: WriteProps): Promise<any>;
export interface WriteDirectPayProps {
    currency: string;
    amount: number;
    module: DirectPayData;
}
interface FundProps {
    cheqId: string;
}
export declare function fund({ cheqId }: FundProps): Promise<void>;
interface ReversePaymentProps {
    cheqId: string;
}
export declare function reverse({ cheqId }: ReversePaymentProps): Promise<void>;
interface BatchPaymentItem {
    amount: number;
    token: string;
    recipient: string;
    note?: string;
}
interface BatchPayment {
    file?: File;
    items: BatchPaymentItem[];
}
export declare function sendBatchPayment({}: BatchPayment): void;
export declare function sendBatchPaymentFromCSV(csv: File): void;
export declare function getNotasQueryURL(): "https://denota.klymr.me/graph/mumbai" | "https://denota.klymr.me/graph/alfajores" | undefined;
export {};
