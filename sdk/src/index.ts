import { BigNumber, ethers, providers } from "ethers";
import erc20 from "./abis/ERC20.sol/TestERC20.json";
import { contractMappingForChainId as contractMappingForChainId_ } from "./chainInfo";

import { ApolloClient, gql, InMemoryCache } from "@apollo/client";
import BridgeSender from "./abis/BridgeSender.sol/BridgeSender.json";
import CheqRegistrar from "./abis/CheqRegistrar.sol/CheqRegistrar.json";
import Events from "./abis/Events.sol/Events.json";
import { uploadMetadata } from "./Metadata";
import { AxelarBridgeData, writeCrossChainNota } from "./modules/AxelarBridge";
import {
  DirectPayData,
  fundDirectPay,
  writeDirectPay,
} from "./modules/DirectPay";
import { MilestonesData, writeMilestones } from "./modules/Milestones";
import {
  cashReversibleRelease,
  fundReversibleRelease,
  ReversibleReleaseData,
  writeReversibleRelease,
} from "./modules/ReversibleRelease";

export const DENOTA_SUPPORTED_CHAIN_IDS = [80001, 44787];

interface BlockchainState {
  signer: ethers.Signer | null;
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

export const state: State = {
  blockchainState: {
    account: "",
    registrar: null,
    registrarAddress: "",
    signer: null,
    directPayAddress: "",
    chainId: 0,
    dai: null,
    weth: null,
    reversibleReleaseAddress: "",
    milestonesAddress: "",
    axelarBridgeSender: null,
  },
};

interface Web3ConnectionProps {
  type: "web3";
  web3Connection: ethers.providers.ExternalProvider;
}

interface PrivateKeyProps {
  type: "privateKey";
  privateKey: string;
  chainId: number;
}

type ProviderProps = Web3ConnectionProps | PrivateKeyProps;

export async function setProvider(input: ProviderProps) {
  let provider: ethers.providers.Provider | null,
    signer: ethers.Signer,
    account: string;

  if (input.type === "privateKey") {
    const { privateKey, chainId } = input as PrivateKeyProps;
    provider = getProviderForChainId(chainId);
    if (provider === null) {
      throw new Error("Unsupported chain");
    }
    signer = new ethers.Wallet(privateKey, provider);
    account = await signer.getAddress();
  } else {
    const { web3Connection } = input as Web3ConnectionProps;
    provider = new ethers.providers.Web3Provider(web3Connection);
    signer = (provider as ethers.providers.Web3Provider).getSigner();
    account = await signer.getAddress();
  }

  const { chainId } = await provider.getNetwork();
  const contractMapping = contractMappingForChainId_(chainId);
  if (contractMapping) {
    const registrar = new ethers.Contract(
      contractMapping.registrar,
      CheqRegistrar.abi,
      signer
    );
    const axelarBridgeSender = new ethers.Contract(
      contractMapping.bridgeSender,
      BridgeSender.abi,
      signer
    );
    const dai = new ethers.Contract(contractMapping.dai, erc20.abi, signer);
    const weth = new ethers.Contract(contractMapping.weth, erc20.abi, signer);
    state.blockchainState = {
      signer,
      account,
      registrarAddress: contractMapping.registrar,
      registrar,
      directPayAddress: contractMapping.directPay,
      chainId,
      dai,
      weth,
      reversibleReleaseAddress: contractMapping.escrow,
      milestonesAddress: contractMapping.milestones,
      axelarBridgeSender,
    };
  } else {
    throw new Error("Unsupported chain");
  }
}

function getProviderForChainId(chainId: number): providers.Provider | null {
  const polygonMumbaiRpcUrl = "https://rpc-mumbai.maticvigil.com/";
  const celoAlfajoresRpcUrl = "https://alfajores-forno.celo-testnet.org/";

  switch (chainId) {
    case 80001: // Polygon Mumbai Testnet
      return new providers.JsonRpcProvider(polygonMumbaiRpcUrl, 80001);
    case 44787: // Celo Alfajores Testnet
      return new providers.JsonRpcProvider(celoAlfajoresRpcUrl, 44787);
    default:
      return null;
  }
}

interface ApproveTokenProps {
  currency: string;
  approvalAmount: number;
}

function tokenForCurrency(currency: string) {
  switch (currency) {
    case "DAI":
      return state.blockchainState.dai;
    case "WETH":
      return state.blockchainState.weth;
  }
}

export function tokenAddressForCurrency(currency: string) {
  switch (currency) {
    case "DAI":
      return state.blockchainState.dai?.address;
    case "WETH":
      return state.blockchainState.weth?.address;
    case "NATIVE":
      return "0x0000000000000000000000000000000000000000";
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

type ModuleData =
  | DirectPayData
  | ReversibleReleaseData
  | MilestonesData
  | AxelarBridgeData;

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
  currency: string;
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
    case "milestones":
      return writeMilestones({ module, ipfsHash, ...props });
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

export function sendBatchPayment({}: BatchPayment) {}

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
