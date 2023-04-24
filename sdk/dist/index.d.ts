import { ethers } from "ethers";
import { AxelarBridgeData } from "./modules/AxelarBridge";
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
    axelarBridgeSender: null | ethers.Contract;
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
export declare function notaIdFromLog(receipt: any): string;
export declare function approveToken({ currency, approvalAmount, }: ApproveTokenProps): Promise<void>;
type ModuleData = DirectPayData | ReversibleReleaseData | MilestonesData | AxelarBridgeData;
export interface WriteProps {
    currency: string;
    amount: number;
    module: ModuleData;
}
export declare function write({ module, ...props }: WriteProps): Promise<{
    txHash: string;
    notaId: string;
}>;
interface FundProps {
    notaId: string;
}
export declare function fund({ notaId }: FundProps): Promise<string | undefined>;
interface CashPaymentProps {
    notaId: string;
    type: "reversal" | "release";
}
export declare function cash({ notaId, type }: CashPaymentProps): Promise<string | undefined>;
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
export declare const contractMappingForChainId: (chainId: number) => {
    DataTypes: string;
    Errors: string;
    Events: string;
    registrar: string;
    escrow: string;
    directPay: string;
    dai: string;
    weth: string;
    milestones: string;
    bridgeReceiver: string;
    bridgeSender: string;
    directPayAxelar: string;
} | undefined;
declare const _default: {
    approveToken: typeof approveToken;
    write: typeof write;
    fund: typeof fund;
    cash: typeof cash;
    sendBatchPayment: typeof sendBatchPayment;
    sendBatchPaymentFromCSV: typeof sendBatchPaymentFromCSV;
    getNotasQueryURL: typeof getNotasQueryURL;
    contractMappingForChainId: (chainId: number) => {
        DataTypes: string;
        Errors: string;
        Events: string;
        registrar: string;
        escrow: string;
        directPay: string;
        dai: string;
        weth: string;
        milestones: string;
        bridgeReceiver: string;
        bridgeSender: string;
        directPayAxelar: string;
    } | undefined;
};
export default _default;
