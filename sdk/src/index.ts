import { BigNumber, ethers } from "ethers";
import erc20 from "./abis/ERC20.sol/TestERC20.json";
import { contractMappingForChainId as contractMappingForChainId_ } from "./chainInfo";
// TODO add the rest of the ABIs
import { uploadMetadata } from "./Metadata";
import Events from "./abis/Events.sol/Events.json";
import NotaRegistrar from "./abis/NotaRegistrar.sol/NotaRegistrar.json";
import { DirectSendData, getDirectSendData, writeDirectSend } from "./modules/DirectSend";
import {
  SimpleCashData,
  cashSimpleCash,
  getSimpleCashData,
  writeSimpleCash,
} from "./modules/SimpleCash";

import {
  CashBeforeDateData,
  cashCashBeforeDate,
  getCashBeforeDateData,
  writeCashBeforeDate,
} from "./modules/CashBeforeDate";
import {
  CashBeforeDateDripData,
  cashCashBeforeDateDrip,
  getCashBeforeDateDripData,
  writeCashBeforeDateDrip,
} from "./modules/CashBeforeDateDrip";
import {
  ReversibleByBeforeDateData,
  cashReversibleByBeforeDate,
  getReversibleByBeforeDateData,
  writeReversibleByBeforeDate,
} from "./modules/ReversibleByBeforeDate";
import {
  ReversibleReleaseData,
  cashReversibleRelease,
  getReversibleReleaseData,
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

// TODO: handle other decimals correctly
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

// TODO need to deal with Nota variables changing on TFCA or nonregistar initiated hook state change
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


export interface Transaction {
  timestamp: Date;
  blockNumber: string;
  hash: string;
}

export interface Written {
  instant: BigNumber;
  escrowed: BigNumber;
  moduleFee: BigNumber;
  writeBytes: string;
  transaction: Transaction;
}

export interface Transfer {
  caller: string;
  from: string;
  to: string;
  moduleFee: BigNumber;
  transferBytes: string;
  transaction: Transaction;
}

export interface Funded {
  caller: string;
  amount: BigNumber;
  instant: BigNumber;
  fundBytes: string;
  moduleFee: BigNumber;
  transaction: Transaction;
}

export interface Cashed {
  caller: string;
  to: string;
  amount: BigNumber;
  cashBytes: string;
  moduleFee: BigNumber;
  transaction: Transaction;
}

export interface Approval {
  caller: string;
  owner: string;
  approved: string;
  transaction: Transaction;
}

export interface MetadataUpdate {
  caller: string;
  transaction: Transaction;
}

export interface Nota {
  // chainId: number;
  id: string;
  token: string;
  escrowed: BigNumber;
  module: string;
  moduleData: ModuleData;

  owner: string;
  approved: string;
  sender: string;
  receiver: string;
  totalAmountSent: BigNumber;  // Total amount that was sent (instant + escrow)
  createdAt: Date;

  written: Written;
  transfers: Transfer[] | null;
  funds: Funded[] | null;
  cashes: Cashed[] | null;
  approvals: Approval[] | null;
  metadataUpdates: MetadataUpdate[] | null;
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
  writeBytes: string;
  externalURI?: string;
  imageURI?: string;
}


export interface WriteProps {
  currency: DenotaCurrency;  // Simplifies DX so they just enter a string instead of address
  amount: number;  // TODO should these be bigNumber? Or union with them?
  instant: number;
  owner: string;
  moduleName: string;  // Simplifies DX so they just enter a string instead of address
  metadata?: RawMetadata | UploadedMetadata;
}

// TODO: could include the chainId for fetching module and currency addresses
// TODO: could remove the moduleData as an input to each write and just return the constructed one instead
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

  let moduleData: ModuleData;  // TODO remove passing moduleData to WTFCA functions?
  switch (moduleName) {
    case "directSend":
      moduleData = {
        moduleName: "directSend",
        status: "paid",
        writeBytes: "",
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
        writeBytes: "",
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
      if (!("reversibleByBeforeDate" in props)) {
        throw new Error("reversibleByBeforeDate is required for reversibleByBeforeDate");
      }
      let reversibleByBeforeDate = props.reversibleByBeforeDate as number;

      moduleData = {
        moduleName: "reversibleByBeforeDate",
        status: "awaiting_claim",
        writeBytes: "",
        inspector: inspector,
        reversibleByBeforeDate: new Date(reversibleByBeforeDate),
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
      if (!("cashBeforeDate" in props)) {
        throw new Error("cashBeforeDate is required for cashBeforeDate");
      }

      let cashBeforeDate = props.cashBeforeDate as number;
      moduleData = {
        moduleName: "cashBeforeDate",
        status: "awaiting_claim",
        writeBytes: "",
        cashBeforeDate: new Date(cashBeforeDate),
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
      if (!("expirationDate" in props)) {
        throw new Error("expirationDate is required for cashBeforeDateDrip");
      }
      if (!("dripAmount" in props)) {
        throw new Error("dripAmount is required for cashBeforeDateDrip");
      }
      if (!("dripPeriod" in props)) {
        throw new Error("dripPeriod is required for cashBeforeDateDrip");
      }

      let expirationDate = props.expirationDate as number;
      moduleData = {
        moduleName: "cashBeforeDateDrip",
        status: "claimable",
        writeBytes: "",
        lastDrip: new Date(0),
        expirationDate: new Date(expirationDate),
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
        writeBytes: "",
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

// TODO: add an `auto` option to fund, which will automatically select the correct fund parameters based on the Nota's module
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

// TODO: add an `auto` option to fund, which will automatically select the correct fund parameters based on the Nota's module
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

// TODO Nota query functionality
// function query(notaId: string): Nota {
// }

// TODO is this actually getting moduleData since a Nota needs to be fed into here anyways?
// TODO need to update the hook moduleDatas without the formatted variables
export function getModuleData(account: string, chainIdNumber: number, nota: Nota, hookAddress: string): ModuleData {
  // TODO should writeBytes be parsed here, beforehand, or in the hook specific one?
  // Note: returns all address variables as lower case for front-end consistency
  account = account.toLowerCase();
  const mapping = contractMappingForChainId(chainIdNumber);
  
  let moduleData: ModuleData = { moduleName: "unknown", status: "?", writeBytes: "", externalURI: "", imageURI: "" };

  let writeBytes;
  try {
    writeBytes = nota.moduleData.writeBytes;
  } catch {
    console.log("No writeBytes found in Nota");
    return moduleData;
  }

  if (mapping) {
    switch (hookAddress) {
      case mapping.simpleCash.toLowerCase():
        moduleData = getSimpleCashData(account, nota, writeBytes);
        break;
      case mapping.cashBeforeDate.toLowerCase():
        moduleData = getCashBeforeDateData(account, nota, writeBytes);
        break;
      case mapping.directSend.toLowerCase():
        moduleData = getDirectSendData(account, nota, writeBytes);
        break;
      case mapping.reversibleByBeforeDate.toLowerCase():
        moduleData = getReversibleByBeforeDateData(account, nota, writeBytes);
        break;
      case mapping.reversibleRelease.toLowerCase():
        moduleData = getReversibleReleaseData(account, nota, writeBytes);
        break;
      case "0x000000005891889951d265d6d7ad3444b68f8887".toLowerCase(): // CashBeforeDateData
        moduleData = getCashBeforeDateData(account, nota, writeBytes);
        break;
      case "0x00000000e8c13602e4d483a90af69e7582a43373".toLowerCase(): // CashBeforeDateDrip
        moduleData = getCashBeforeDateDripData(account, nota, writeBytes);
        break;
      case "0x00000000cce992072e23cda23a1986f2207f5e80".toLowerCase(): // CashBeforeDateDrip
        moduleData = getCashBeforeDateDripData(account, nota, writeBytes);
        break;
      case "0x00000000123157038206fefeb809823016331ff2".toLowerCase(): // CashBeforeDate
        moduleData = getCashBeforeDateData(account, nota, writeBytes);
        break;
      case "0x00000000115e79ea19439db1095327acbd810bf7".toLowerCase():  // ReversibleByBeforeDate
        moduleData = getReversibleReleaseData(account, nota, writeBytes);
        break;
      case "0x00000003672153A114583FA78C3D313D4E3cAE40".toLowerCase(): // DirectSend
        moduleData = getDirectSendData(account, nota, writeBytes);
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
