export declare const DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";
export declare const DENOTA_SUPPORTED_CHAIN_IDS: number[];
export declare function setProvider(web3Connection: any): Promise<void>;
export declare function getProvider(): void;
interface ApproveTokenProps {
    token: string;
    approvalAmount: number;
}
export declare function approveToken({}: ApproveTokenProps): void;
export interface DirectPayData {
    moduleName: "Direct";
    type: "invoice" | "payment";
    creditor: string;
    debitor: string;
    notes?: string;
    file?: File;
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
export declare function write({ module }: WriteProps): void;
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
export declare function fetchNotas(query: string): void;
export {};
