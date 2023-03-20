import { ethers } from "ethers";
export declare const DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";
import { DirectPayData } from "./modules/DirectPay";
export declare const DENOTA_SUPPORTED_CHAIN_IDS: number[];
interface BlockchainState {
    signer: ethers.providers.JsonRpcSigner | null;
    registrar: ethers.Contract | null;
    account: string;
    chainId: number;
    directPayAddress: string;
    registrarAddress: string;
    dai: ethers.Contract | null;
    weth: ethers.Contract | null;
}
interface State {
    blockchainState: BlockchainState;
}
export declare const state: State;
export declare function setProvider(web3Connection: any): Promise<void>;
interface ApproveTokenProps {
    currency: string;
    approvalAmount: number;
}
export declare function tokenAddressForCurrency(currency: string): string | undefined;
export declare function approveToken({ currency, approvalAmount, }: ApproveTokenProps): Promise<void>;
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
export declare function write({ module, amount, currency }: WriteProps): Promise<string | undefined>;
interface FundProps {
    cheqId: string;
}
export declare function fund({ cheqId }: FundProps): Promise<void>;
interface CashPaymentProps {
    cheqId: string;
    type: "reversal" | "release";
}
export declare function cash({ cheqId }: CashPaymentProps): Promise<void>;
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
declare const _default: {
    approveToken: typeof approveToken;
    write: typeof write;
    fund: typeof fund;
    cash: typeof cash;
    sendBatchPayment: typeof sendBatchPayment;
    sendBatchPaymentFromCSV: typeof sendBatchPaymentFromCSV;
    getNotasQueryURL: typeof getNotasQueryURL;
};
export default _default;
