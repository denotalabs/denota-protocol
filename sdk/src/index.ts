import { BigNumber, ethers } from "ethers";
import erc20 from "./abis/ERC20.sol/TestERC20.json";
import { contractMappingForChainId as contractMappingForChainId_ } from "./chainInfo";

import Events from "./abis/Events.sol/Events.json";
import NotaRegistrar from "./abis/NotaRegistrar.sol/NotaRegistrar.json";
import { uploadMetadata } from "./Metadata";
import { DirectPayData, writeDirectPay } from "./modules/DirectPay";
import {
  cashReversibleRelease,
  ReversibleReleaseData,
  writeReversibleRelease,
} from "./modules/ReversibleRelease";
import {
  cashSimpleCash,
  SimpleCashData,
  writeSimpleCash,
} from "./modules/SimpleCash";
import { cashCashBeforeDate, CashBeforeDateData, writeCashBeforeDate } from "./modules/CashBeforeDate";

export const DENOTA_SUPPORTED_CHAIN_IDS = [80001, 44787];

export type DenotaCurrency = "DAI" | "WETH" | "USDC" | "USDCE" | "USDT" | "GET";

interface ContractMapping {
  DataTypes: string;
  Errors: string;
  Events: string;
  registrar: string;
  reversibleRelease: string;
  directPay: string;
  simpleCash: string;
  cashBeforeDate: string;
  dai: string;
  weth: string;
  milestones: string;
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
      DataTypes: "",
      Errors: "",
      Events: "",
      registrar: "",
      directPay: "",
      reversibleRelease: "",
      simpleCash: "",
      cashBeforeDate: "",
      dai: "",
      weth: "",
      milestones: "",
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

type ModuleData = DirectPayData | ReversibleReleaseData | SimpleCashData | CashBeforeDateData;
type NotaModule = "directPay" | "reversibleRelease" | "simpleCash" | "cashBeforeDate";

interface RawMetadata {
  type: "raw";
  notes?: string;
  file?: File;
  tags?: string;
}

interface UploadedMetadata {
  type: "uploaded";
  ipfsHash: string;
  imageUrl?: string;
}

export interface WriteProps {
  currency: DenotaCurrency;
  amount: number;
  metadata?: RawMetadata | UploadedMetadata;

  module: ModuleData;
}

export async function write({ module, metadata, ...props }: WriteProps) {
  let ipfsHash = "",
    imageUrl = "";

  if (metadata?.type === "uploaded") {
    ipfsHash = metadata.ipfsHash;
    imageUrl = metadata.imageUrl ?? "";
  }

  if (metadata?.type === "raw") {
    const { imageUrl: uploadedImageUrl, ipfsHash: uploadedHash } =
      await uploadMetadata(metadata.file, metadata.notes, metadata.tags);
    imageUrl = uploadedImageUrl ?? "";
    ipfsHash = uploadedHash ?? "";
  }

  switch (module.moduleName) {
    case "direct":
      return await writeDirectPay({ module, ipfsHash, imageUrl, ...props });
    case "reversibleRelease":
      return await writeReversibleRelease({
        module,
        externalUrl: ipfsHash,
        imageUrl,
        ...props,
      });
    case "cashBeforeDate":
      return await writeCashBeforeDate({
        module,
        externalUrl: ipfsHash,
        imageUrl,
        ...props,
      });
    case "simpleCash":
      return await writeSimpleCash({ module, ...props });
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

interface CashPaymentProps {
  notaId: string;
  type: "reversal" | "release";
  amount: BigNumber;
  to: string;
  module: NotaModule;
}

export async function cash({
  notaId,
  type,
  amount,
  to,
  module,
}: CashPaymentProps) {
  switch (module) {
    case "reversibleRelease":
      return await cashReversibleRelease({
        notaId,
        to,
        amount,
      });
      case "cashBeforeDate":
        return await cashCashBeforeDate({ notaId, to, amount });
    case "simpleCash":
      return await cashSimpleCash({ notaId, to, amount });
  }
}

export const contractMappingForChainId = contractMappingForChainId_;

export default {
  approveToken,
  write,
  fund,
  cash,
  contractMappingForChainId,
};
