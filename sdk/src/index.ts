import { BigNumber, ethers } from "ethers";
import erc20 from "./abis/ERC20.sol/TestERC20.json";
import { contractMappingForChainId as contractMappingForChainId_ } from "./chainInfo";

import { ApolloClient, gql, InMemoryCache } from "@apollo/client/core";
import BridgeSender from "./abis/BridgeSender.sol/BridgeSender.json";
import NotaRegistrar from "./abis/CheqRegistrar.sol/CheqRegistrar.json";
import Events from "./abis/Events.sol/Events.json";
import MultiDisperse from "./abis/MultiDisperse.sol/MultiDisperse.json";
import { BatchDisperse, BatchProps } from "./batch/BatchDisperse";
import { uploadMetadata } from "./Metadata";
import { AxelarBridgeData, writeCrossChainNota } from "./modules/AxelarBridge";
import {
  DirectPayData,
  fundDirectPay,
  writeDirectPay,
} from "./modules/DirectPay";
import {
  cashReversibleRelease,
  fundReversibleRelease,
  ReversibleReleaseData,
  writeReversibleRelease,
} from "./modules/ReversibleRelease";

export const DENOTA_SUPPORTED_CHAIN_IDS = [80001, 44787];

export type DenotaCurrency = "DAI" | "WETH" | "USDC" | "USDCE" | "USDT";

interface ContractMapping {
  DataTypes: string;
  Errors: string;
  Events: string;
  registrar: string;
  reversibleRelease: string;
  directPay: string;
  dai: string;
  weth: string;
  milestones: string;
  bridgeReceiver: string;
  bridgeSender: string;
  directPayAxelar: string;
  batch: string;
  usdc: string;
  usdce: string;
  usdt: string;
}

interface BlockchainState {
  signer: ethers.Signer | null;
  registrar: ethers.Contract | null;
  account: string;
  chainId: number;
  axelarBridgeSender: null | ethers.Contract;
  disperse: null | ethers.Contract;
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
    axelarBridgeSender: null,
    disperse: null,
    contractMapping: {
      DataTypes: "",
      Errors: "",
      Events: "",
      registrar: "",
      directPay: "",
      reversibleRelease: "",
      dai: "",
      weth: "",
      milestones: "",
      bridgeReceiver: "",
      bridgeSender: "",
      directPayAxelar: "",
      batch: "",
      usdc: "",
      usdce: "",
      usdt: "",
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

    const axelarBridgeSender = new ethers.Contract(
      contractMapping.bridgeSender,
      BridgeSender.abi,
      signer
    );

    const disperse = new ethers.Contract(
      contractMapping.batch,
      MultiDisperse.abi,
      signer
    );

    state.blockchainState = {
      signer,
      account,
      registrar,
      chainId,
      axelarBridgeSender,
      disperse,
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

type ModuleData = DirectPayData | ReversibleReleaseData | AxelarBridgeData;

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
        ipfsHash,
        imageUrl,
        ...props,
      });
    case "crosschain":
      return writeCrossChainNota({ module, ipfsHash, imageUrl, ...props });
  }
}

interface FundProps {
  notaId: string;
}

export async function fund({ notaId }: FundProps) {
  const notaQuery = `
  query cheqs($cheq: String ){
    cheqs(where: { id: $cheq }, first: 1)  {
      erc20 {
        id
      }
      moduleData {
        ... on DirectPayData {
          __typename
          amount
        }
        ... on ReversiblePaymentData {
          __typename
          amount
        }
      }
    }
  }
`;

  const client = new ApolloClient({
    uri: getNotasQueryURL(),
    cache: new InMemoryCache(),
  });

  const data = await client.query({
    query: gql(notaQuery),
    variables: {
      cheq: notaId,
    },
  });

  const nota = data["data"]["cheqs"][0];
  const amount = BigNumber.from(nota.moduleData.amount);

  switch (nota.moduleData.__typename) {
    case "DirectPayData":
      return await fundDirectPay({
        notaId,
        amount,
        tokenAddress: nota.erc20.id,
      });
    case "ReversiblePaymentData":
      return await fundReversibleRelease({
        notaId,
        amount,
        tokenAddress: nota.erc20.id,
      });
  }
}

interface CashPaymentProps {
  notaId: string;
  type: "reversal" | "release";
}

export async function cash({ notaId, type }: CashPaymentProps) {
  const notaQuery = `
    query cheqs($cheq: String ){
      cheqs(where: { id: $cheq }, first: 1)  {
        moduleData {
          ... on DirectPayData {
            __typename
            amount
            creditor {
              id
            }
            debtor {
              id
            }
            dueDate
          }
          ... on ReversiblePaymentData {
            __typename
            amount
            creditor {
              id
            }
            debtor {
              id
            }
          }
        }
    }
    }
  `;

  const client = new ApolloClient({
    uri: getNotasQueryURL(),
    cache: new InMemoryCache(),
  });

  const data = await client.query({
    query: gql(notaQuery),
    variables: {
      cheq: notaId,
    },
  });

  const nota = data["data"]["cheqs"][0];
  const amount = BigNumber.from(nota.moduleData.amount);

  switch (nota.moduleData.__typename) {
    case "ReversiblePaymentData":
      return await cashReversibleRelease({
        notaId,
        creditor: nota.moduleData.creditor.id,
        debtor: nota.moduleData.debtor.id,
        amount,
        type,
      });
  }
}

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

export async function sendBatchPayment(props: BatchProps) {
  return await BatchDisperse(props);
}

export function sendBatchPaymentFromCSV(csv: File) {}

export function getNotasQueryURL() {
  switch (state.blockchainState.chainId) {
    case 80001:
      return "https://denota.klymr.me/graph/mumbai";
    case 44787:
      return "https://denota.klymr.me/graph/alfajores";
    default:
      return undefined;
  }
}

export const contractMappingForChainId = contractMappingForChainId_;

export default {
  approveToken,
  write,
  fund,
  cash,
  sendBatchPayment,
  sendBatchPaymentFromCSV,
  getNotasQueryURL,
  contractMappingForChainId,
};
