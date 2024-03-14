import { BigNumber, ethers } from "ethers";
import erc20 from "./abis/ERC20.sol/TestERC20.json";
import { contractMappingForChainId as contractMappingForChainId_ } from "./chainInfo";
// TODO add the rest of the ABIs
import { uploadMetadata } from "./Metadata";
import Events from "./abis/Events.sol/Events.json";
import NotaRegistrar from "./abis/NotaRegistrar.sol/NotaRegistrar.json";
import { DirectSendData, writeDirectSend, getDirectSendData } from "./modules/DirectSend";
import {
  SimpleCashData,
  getSimpleCashData,
  cashSimpleCash,
  writeSimpleCash,
} from "./modules/SimpleCash";

import {
  CashBeforeDateData,
  getCashBeforeDateData,
  cashCashBeforeDate,
  writeCashBeforeDate,
} from "./modules/CashBeforeDate";
import {
  CashBeforeDateDripData,
  getCashBeforeDateDripData,
  cashCashBeforeDateDrip,
  writeCashBeforeDateDrip,
} from "./modules/CashBeforeDateDrip";
import {
  ReversibleByBeforeDateData,
  getReversibleByBeforeDateData,
  cashReversibleByBeforeDate,
  writeReversibleByBeforeDate,
} from "./modules/ReversibleByBeforeDate";
import {
  ReversibleReleaseData,
  getReversibleReleaseData,
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
  tags?: string;
  file?: File;
}

interface UploadedMetadata {
  type: "uploaded";
  externalURI: string;
  imageURI?: string;
}

export type UnknownModuleStatus = "?";

export interface UnknownModuleData {
  status: UnknownModuleStatus;
  moduleName: "unknown";
  externalURI?: string;
  imageURI?: string;
}

export type ModuleData =
  | DirectSendData
  | SimpleCashData
  | CashBeforeDateData
  | CashBeforeDateDripData
  | ReversibleReleaseData
  | ReversibleByBeforeDateData
  | UnknownModuleData;

export type NotaModuleNames =
  | "directSend"
  | "simpleCash"
  | "cashBeforeDate"
  | "cashBeforeDateDrip"
  | "reversibleRelease"
  | "reversibleByBeforeDate";

export type NotaStatuses = "paid" | "claimable" | "awaiting_claim" | "awaiting_release" | "releasable" | "released" | "claimed" | "expired" | "returnable" | "returned" | "locked" | "?";


export interface WriteProps {
  currency: DenotaCurrency;  // Simplifies DX so they just enter a string instead of address
  amount: number;
  instant: number;
  owner: string;
  moduleName: string;  // Simplifies DX so they just enter a string instead of address
  metadata?: RawMetadata | UploadedMetadata;
}

// TODO: could include the chainId for fetching module and currency addresses
// TODO could remove the moduleData moduleName and status as an input and return the constructed one instead
export async function write({ currency, amount, instant, owner, moduleName, metadata, ...props }: WriteProps) {
  let externalURI = "",
    imageURI = "";

  if (metadata?.type === "uploaded") {
    externalURI = metadata.externalURI;
    imageURI = metadata.imageURI ?? "";
  }

  if (metadata?.type === "raw") {
    const { imageURI: uploadedimageURI, ipfsHash: uploadedHash } =
      await uploadMetadata(metadata.file, metadata.notes, metadata.tags);
    imageURI = uploadedimageURI ?? "";
    externalURI = uploadedHash ?? "";
  }
  
  let moduleData: ModuleData;
  switch (moduleName) {
    case "directSend":
      moduleData = {
        moduleName: "directSend",
        status: "paid",
        externalURI: externalURI,
        imageURI: imageURI,
      };
      return await writeDirectSend({ currency, amount, owner, moduleData });
    case "reversibleRelease":
      let inspector = ("inspector" in props) ? props.inspector as string : owner;
      moduleData = {
        moduleName: "reversibleRelease",
        status: "awaiting_release",
        inspector: inspector,
        externalURI: externalURI,
        imageURI: imageURI,
      };
      return await writeReversibleRelease({
        currency,
        amount,
        instant,
        owner,
        moduleData,
      });
    case "reversibleByBeforeDate":
      inspector = ("inspector" in props) ? props.inspector as string : owner;
      if (!("reversibleByBeforeDate" in props)){
        throw new Error("reversibleByBeforeDate is required for reversibleByBeforeDate");
      }
      moduleData = {
        moduleName: "reversibleByBeforeDate",
        status: "awaiting_claim",
        inspector: inspector,
        reversibleByBeforeDate: instant,
        externalURI: externalURI,
        imageURI: imageURI,
      };
      return await writeReversibleByBeforeDate({
        currency,
        amount,
        instant,
        owner,
        moduleData,
      });
    case "cashBeforeDate":
      if (!("cashBeforeDate" in props)){
        throw new Error("cashBeforeDate is required for cashBeforeDate");
      }
      moduleData = {
        moduleName: "cashBeforeDate",
        status: "awaiting_claim",
        cashBeforeDate: props.cashBeforeDate as number,
        externalURI: externalURI,
        imageURI: imageURI,
      };
      return await writeCashBeforeDate({
        currency,
        amount,
        instant,
        owner,
        moduleData,
      });
    case "cashBeforeDateDrip":
        if (!("expirationDate" in props)){
          throw new Error("expirationDate is required for cashBeforeDateDrip");
        }
        if (!("dripAmount" in props)){
          throw new Error("dripAmount is required for cashBeforeDateDrip");
        }
        if (!("dripPeriod" in props)){
          throw new Error("dripPeriod is required for cashBeforeDateDrip");
        }
        moduleData = {
          moduleName: "cashBeforeDateDrip",
          status: "locked",
          expirationDate: props.expirationDate as number,
          dripAmount: props.dripAmount as number,
          dripPeriod: props.dripPeriod as number,
          externalURI: externalURI,
          imageURI: imageURI,
        };
        return await writeCashBeforeDateDrip({
          currency,
          amount,
          instant,
          owner,
          moduleData,
        });
    case "simpleCash":
      moduleData = {
        moduleName: "simpleCash",
        status: "claimable",
        externalURI: externalURI,
        imageURI: imageURI,
      };
      return await writeSimpleCash({
        currency,
        amount,
        instant,
        owner,
        moduleData
       });
    default:
      throw new Error("Unknown module");
  }
}

interface FundProps {
  notaId: string;
  amount: BigNumber;
  moduleName: NotaModuleNames;
}

export async function fund({ notaId, amount, moduleName }: FundProps) {
  // Implement in future modules
}

// Should each module inherit from a shared interface?
interface CashPaymentProps {
  notaId: string;
  amount: BigNumber;
  to: string;
  moduleName: NotaModuleNames;  // Cashing doesn't need the module on the SC side
  type: "reversal" | "release";  // TODO what state does this refer to?
}

export async function cash({
  notaId,
  type,  // TODO remove
  amount,
  to,
  moduleName,
}: CashPaymentProps) {
  switch (moduleName) {
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

export interface NotaTransaction {
  date: Date; // timestamp
  hash: string; // transactionHash
}

export interface Nota {
  chainId: number;
  id: string;
  token: string;
  amount: number;
  amountRaw: BigNumber;
  moduleData: ModuleData;

  owner: string;
  approved: string;
  sender: string;
  receiver: string;
  createdTransaction: NotaTransaction;
  fundedTransaction: NotaTransaction[] | null;  // TODO have list of WTFCA transactions
  cashedTransaction: NotaTransaction[] | null;
}

// TODO ModuleData.decode functionality
// TODO Nota query functionality
// function query(notaId: string) {
  //// nota.moduleBytes.decode();
// }

export function getModuleData(account: string, chainIdNumber: number, nota: any, hookAddress: string): ModuleData {
  // TODO should `nota` be a Nota object or just the bytes data?
  // returns all address variables as lower case for front-end consistency
  account = account.toLowerCase();
  const mapping = contractMappingForChainId(chainIdNumber);

  let moduleData: ModuleData = { moduleName: "unknown", status: "?", externalURI: "", imageURI: ""};
  if (mapping) {
    switch (hookAddress) {
      case mapping.simpleCash.toLowerCase():
        moduleData = getSimpleCashData(account, nota, hookAddress);
        break;
      case mapping.cashBeforeDate.toLowerCase():
        moduleData = getCashBeforeDateData(account, nota, hookAddress);
        break;
      case mapping.directSend.toLowerCase():
        moduleData = getDirectSendData(account, nota, hookAddress);
        break;
      case mapping.reversibleByBeforeDate.toLowerCase():
        moduleData = getReversibleByBeforeDateData(account, nota, hookAddress);
        break;
      case mapping.reversibleRelease.toLowerCase():
        moduleData = getReversibleReleaseData(account, nota, hookAddress);
        break;
      case "0x000000005891889951d265d6d7ad3444b68f8887".toLowerCase(): // CashBeforeDateData
        moduleData = getCashBeforeDateData(account, nota, hookAddress);
        break;
      case "0x00000000e8c13602e4d483a90af69e7582a43373".toLowerCase(): // CashBeforeDateDrip
        moduleData = getCashBeforeDateDripData(account, nota, hookAddress);
        break;
      case "0x00000000cce992072e23cda23a1986f2207f5e80".toLowerCase(): // CashBeforeDateDrip
        moduleData = getCashBeforeDateDripData(account, nota, hookAddress);
        break;
      case "0x00000000123157038206fefeb809823016331ff2".toLowerCase(): // CashBeforeDate
        moduleData = getCashBeforeDateData(account, nota, hookAddress);
        break;
      case "0x00000000115e79ea19439db1095327acbd810bf7".toLowerCase():  // ReversibleByBeforeDate
        moduleData = getReversibleReleaseData(account, nota, hookAddress);
        break;
      case "0x00000003672153A114583FA78C3D313D4E3cAE40".toLowerCase(): // DirectSend
        moduleData = getDirectSendData(account, nota, hookAddress);
        break;
    }
  }
  return moduleData;
}

export default {
  approveToken,
  write,
  fund,
  cash,
  contractMappingForChainId,
  getModuleData,
};
