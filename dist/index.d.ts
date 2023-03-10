export declare const DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";
export declare const DENOTA_SUPPORTED_CHAIN_IDS: number[];
export declare function setProvider(web3Connection: any): Promise<void>;
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
interface ApproveTokenProps {
    token: string;
    approvalAmount: number;
}
export declare function approveToken({}: ApproveTokenProps): void;
interface DirectPayProps {
    recipient: string;
    token: string;
    amount: number;
    note?: string;
    file?: File;
}
export declare function sendDirectPayment({ recipient, token, amount, note, file, }: DirectPayProps): void;
export declare function sendDirectPayInvoice({ recipient, token, amount, note, file, }: DirectPayProps): void;
interface FundDirectPayProps {
    cheqId: number;
}
export declare function fundDirectPayInvoice({}: FundDirectPayProps): void;
interface ReversiblePaymentProps {
    recipient: string;
    token: string;
    amount: number;
    note?: string;
    file?: File;
    inspectionPeriod: number;
    fundedPercentage: number;
}
export declare function sendReversiblePayent({}: ReversiblePaymentProps): void;
export declare function sendReversibleInvoice({}: ReversiblePaymentProps): void;
interface ReversePaymentProps {
    cheqId: number;
}
export declare function reversePayment({}: ReversePaymentProps): void;
interface Milestone {
    amount: number;
    note: string;
    targetCompletion: Date;
}
interface MilestoneProps {
    milestones: Milestone[];
    token: string;
    recipient: string;
    file: File;
}
export declare function sendMilestoneInvoice({}: MilestoneProps): void;
interface MilestonePaymentProps extends MilestoneProps {
    fundedMilestones: number[];
}
export declare function sendMilestonePayment({}: MilestonePaymentProps): void;
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
