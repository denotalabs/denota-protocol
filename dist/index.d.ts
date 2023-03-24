import { ethers } from "ethers";
export declare const DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";
import { DirectPayData } from "./modules/DirectPay";
import { MilestonesData } from "./modules/Milestones";
import { ReversibleReleaseData } from "./modules/ReversibleRelease";
export declare const DENOTA_SUPPORTED_CHAIN_IDS: number[];
interface BlockchainState {
    signer: ethers.providers.JsonRpcSigner | null;
    registrar: ethers.Contract | null;
    account: string;
    chainId: number;
    directPayAddress: string;
    reversibleReleaseAddress: string;
    registrarAddress: string;
    dai: ethers.Contract | null;
    weth: ethers.Contract | null;
    milestonesAddress: string;
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
declare type ModuleData = DirectPayData | ReversibleReleaseData | MilestonesData;
export interface WriteProps {
    currency: string;
    amount: number;
    module: ModuleData;
}
export declare function write({ module, ...props }: WriteProps): Promise<string | void>;
interface FundProps {
    cheqId: string;
}
export declare function fund({ cheqId }: FundProps): Promise<void>;
interface CashPaymentProps {
    cheqId: string;
    type: "reversal" | "release";
}
export declare function cash({ cheqId, type }: CashPaymentProps): Promise<string | undefined>;
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
