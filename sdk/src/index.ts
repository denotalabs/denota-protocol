import { BigNumber, ethers } from "ethers";
import erc20 from "./abis/ERC20.sol/TestERC20.json";
import { contractMappingForChainId as contractMappingForChainId_ } from "./chainInfo";

import { uploadMetadata } from "./Metadata";
import Events from "./abis/Events.sol/Events.json";
import NotaRegistrar from "./abis/NotaRegistrar.sol/NotaRegistrar.json";
import { DirectSendData, writeDirectSend, directSendStatus } from "./modules/DirectSend";
import {
  SimpleCashData,
  simpleCashStatus,
  cashSimpleCash,
  writeSimpleCash,
} from "./modules/SimpleCash";

import {
  CashBeforeDateData,
  cashBeforeDateStatus,
  cashCashBeforeDate,
  writeCashBeforeDate,
} from "./modules/CashBeforeDate";
import {
  CashBeforeDateDripData,
  cashBeforeDateDripStatus,
  cashCashBeforeDateDrip,
  writeCashBeforeDateDrip,
} from "./modules/CashBeforeDateDrip";
import {
  ReversibleByBeforeDateData,
  reversibleByBeforeDateStatus,
  cashReversibleByBeforeDate,
  writeReversibleByBeforeDate,
} from "./modules/ReverseByBeforeDate";
import {
  ReversibleReleaseData,
  reversibleReleaseStatus,
  cashReversibleRelease,
  writeReversibleRelease,
} from "./modules/ReversibleRelease";

export const DENOTA_SUPPORTED_CHAIN_IDS = [137, 80001, 44787];

export type DenotaCurrency = "DAI" | "WETH" | "USDC" | "USDCE" | "USDT" | "GET";

interface ContractMapping {
  registrar: string;
  directSend: string;
  simpleCash: string;
  cashBeforeDate: string;
  cashBeforeDateDrip: string;
  reversibleRelease: string;
  reversibleByBeforeDate: string;
  dai: string;
  weth: string;
  batch: string;
  usdc: string;
  usdce: string;
  usdt: string;
  get: string;
}

interface BlockchainState {
  signer: ethers.Signer | null;
  registrar: ethers.Contract | null;
  account: string;
  chainId: number;
  contractMapping: ContractMapping;
}

interface State {
  blockchainState: BlockchainState;
}

export const state: State = {
  blockchainState: {
    account: "",
    registrar: null,
    signer: null,
    chainId: 0,
    contractMapping: {
      registrar: "",
      directSend: "",
      simpleCash: "",
      cashBeforeDate: "",
      cashBeforeDateDrip: "",
      reversibleRelease: "",
      reversibleByBeforeDate: "",
      dai: "",
      weth: "",
      batch: "",
      usdc: "",
      usdce: "",
      usdt: "",
      get: "",
    },
  },
};

interface ProviderProps {
  chainId: number;
  signer: ethers.Signer;
}

export async function setProvider({ signer, chainId }: ProviderProps) {
  const account = await signer.getAddress();

  const contractMapping = contractMappingForChainId_(chainId);
  if (contractMapping) {
    const registrar = new ethers.Contract(
      contractMapping.registrar,
      NotaRegistrar.abi,
      signer
    );

    state.blockchainState = {
      signer,
      account,
      registrar,
      chainId,
      contractMapping,
    };
  } else {
    throw new Error("Unsupported chain");
  }
}

interface ApproveTokenProps {
  currency: string;
  approvalAmount: number;
}

function tokenForCurrency(currency: string) {
  const contractMapping = state.blockchainState.contractMapping;
  const signer = state.blockchainState.signer;

  if (signer) {
    switch (currency) {
      case "DAI":
        return new ethers.Contract(contractMapping.dai, erc20.abi, signer);
      case "WETH":
        return new ethers.Contract(contractMapping.weth, erc20.abi, signer);
      case "USDC":
        return new ethers.Contract(contractMapping.usdc, erc20.abi, signer);
      case "USDT":
        return new ethers.Contract(contractMapping.usdt, erc20.abi, signer);
      case "USDCE":
        return new ethers.Contract(contractMapping.usdce, erc20.abi, signer);
      case "GET":
        return new ethers.Contract(contractMapping.get, erc20.abi, signer);
    }
  }
}

export function tokenAddressForCurrency(currency: string) {
  const contractMapping = state.blockchainState.contractMapping;
  switch (currency) {
    case "DAI":
      return contractMapping.dai;
    case "WETH":
      return contractMapping.weth;
    case "USDC":
      return contractMapping.usdc;
    case "USDCE":
      return contractMapping.usdce;
    case "USDT":
      return contractMapping.usdt;
    case "GET":
      return contractMapping.get;
  }
}

export function tokenDecimalsForCurrency(currency: string) {
  switch (currency) {
    case "USDC":
    case "USDCE":
    case "USDT":
      return 6;
    default:
      return 18;
  }
}

export function notaIdFromLog(receipt: any) {
  const iface = new ethers.utils.Interface(Events.abi);

  const writtenLog = receipt.logs
    .map((log: any) => {
      try {
        return iface.parseLog(log);
      } catch {
        return {};
      }
    })
    .filter((log: any) => {
      return log.name === "Written";
    });

  const id = writtenLog[0].args[1] as BigNumber;
  return id.toString();
}

export async function approveToken({
  currency,
  approvalAmount,
}: ApproveTokenProps) {
  const token = tokenForCurrency(currency);
  const amountWei = ethers.utils.parseEther(String(approvalAmount));

  const tx = await token?.functions.approve(
    state.blockchainState.registrar,
    amountWei
  );
  await tx.wait();
}

interface RawMetadata {
  type: "raw";
  notes?: string;
  file?: File;
  tags?: string;
}

interface UploadedMetadata {
  type: "uploaded";
  externalUrl: string;
  imageUrl?: string;
}

export type UnknownModuleStatus = "?";

export interface UnknownModuleData {
  status: UnknownModuleStatus;
  moduleName: "unknown";
}

type ModuleData =
  | DirectSendData
  | SimpleCashData
  | CashBeforeDateData
  | CashBeforeDateDripData
  | ReversibleReleaseData
  | ReversibleByBeforeDateData
  | UnknownModuleData;

type NotaModule =
  | "directSend"
  | "simpleCash"
  | "cashBeforeDate"
  | "cashBeforeDateDrip"
  | "reversibleRelease"
  | "reversibleByBeforeDate";

export type NotaStatus = "paid" | "claimable" | "awaiting_claim" | "awaiting_release" | "releasable" | "released" | "claimed" | "expired" | "returnable" | "returned" | "locked" | "?";


export interface WriteProps {
  currency: DenotaCurrency;
  amount: number;
  metadata?: RawMetadata | UploadedMetadata;

  module: ModuleData;
}

export async function write({ module, metadata, ...props }: WriteProps) {
  let externalUrl = "",
    imageUrl = "";

  if (metadata?.type === "uploaded") {
    externalUrl = metadata.externalUrl;
    imageUrl = metadata.imageUrl ?? "";
  }

  if (metadata?.type === "raw") {
    const { imageUrl: uploadedImageUrl, ipfsHash: uploadedHash } =
      await uploadMetadata(metadata.file, metadata.notes, metadata.tags);
    imageUrl = uploadedImageUrl ?? "";
    externalUrl = uploadedHash ?? "";
  }

  switch (module.moduleName) {
    case "directSend":
      return await writeDirectSend({ module, externalUrl, imageUrl, ...props });
    case "reversibleRelease":
      return await writeReversibleRelease({
        module,
        externalUrl,
        imageUrl,
        ...props,
      });
    case "reversibleByBeforeDate":
      return await writeReversibleByBeforeDate({
        module,
        externalUrl,
        imageUrl,
        ...props,
      });
    case "cashBeforeDate":
      return await writeCashBeforeDate({
        module,
        externalUrl,
        imageUrl,
        ...props,
      });
      case "cashBeforeDateDrip":
        return await writeCashBeforeDateDrip({
          module,
          externalUrl,
          imageUrl,
          ...props,
        });
    case "simpleCash":
      return await writeSimpleCash({ module, ...props });
    default:
      throw new Error("Unknown module");
  }
}

interface FundProps {
  notaId: string;
  amount: BigNumber;
  module: NotaModule;
}

export async function fund({ notaId, amount, module }: FundProps) {
  // Implement in future modules
}

// Should each module inherit from a shared interface?
interface CashPaymentProps {
  notaId: string;
  amount: BigNumber;
  to: string;
  module: NotaModule;  // Cashing doesn't need the module on the SC side
  type: "reversal" | "release";  // TODO what state does this refer to?
}

export async function cash({
  notaId,
  type,  // TODO remove
  amount,
  to,
  module,
}: CashPaymentProps) {
  switch (module) {
    // Need to add cashBeforeDateDrip
    case "simpleCash":
      return await cashSimpleCash({ notaId, to, amount });
    case "cashBeforeDate":
      return await cashCashBeforeDate({ notaId, to, amount });  
    case "reversibleRelease":
      return await cashReversibleRelease({
        notaId,
        to,
        amount,
      });
    case "reversibleByBeforeDate":
      return await cashReversibleByBeforeDate({
        notaId,
        to,
        amount,
      });
      case "cashBeforeDateDrip":
        return await cashCashBeforeDateDrip({
          notaId,
          to,
          amount,
        });
      default:
        throw new Error("Unknown module");
  }
}

export const contractMappingForChainId = contractMappingForChainId_;

// TODO need to query Notas and define their interface
// function query(notaId: string) {
// }

export function status(chainIdNumber: number, account: string, nota: any, hookAddress: string) {
  let status: string;
  const mapping = contractMappingForChainId(chainIdNumber);
  if (mapping) {
      switch (hookAddress) {
        case mapping.simpleCash.toLowerCase():
          status = simpleCashStatus(hookAddress, nota, account);
        case mapping.cashBeforeDate.toLowerCase():
          status = cashBeforeDateStatus(hookAddress, nota, account);
        case "0x000000005891889951d265d6d7ad3444b68f8887".toLowerCase():  // TODO remove
          status = cashBeforeDateStatus(hookAddress, nota, account);
        case "0x00000000e8c13602e4d483a90af69e7582a43373".toLowerCase():  // CashBeforeDateDrip
          status = cashBeforeDateDripStatus(hookAddress, nota, account);
        case mapping.reversibleRelease.toLowerCase():
          status = reversibleReleaseStatus(hookAddress, nota, account);
        case "0x00000000115e79ea19439db1095327acbd810bf7".toLowerCase():
          status = reversibleReleaseStatus(hookAddress, nota, account);
        case "0x00000003672153A114583FA78C3D313D4E3cAE40".toLowerCase(): // DirectSend
          status = "paid";
        case mapping.reversibleByBeforeDate.toLowerCase():
          status = reversibleByBeforeDateStatus(hookAddress, nota, account);
        case mapping.directSend.toLowerCase():
          status = directSendStatus(hookAddress, nota, account);
        default:
          status = "?";
    }
  } else {
    status = "?";
  }
}

export default {
  approveToken,
  write,
  fund,
  cash,
  contractMappingForChainId,
  status,
};
