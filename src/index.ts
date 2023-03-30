import { BigNumber, ethers } from "ethers";
import erc20 from "./abis/ERC20.sol/TestERC20.json";
import { contractMappingForChainId } from "./chainInfo";

export const DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";

import { ApolloClient, gql, InMemoryCache } from "@apollo/client";
import CheqRegistrar from "./abis/CheqRegistrar.sol/CheqRegistrar.json";
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

export const DENOTA_SUPPORTED_CHAIN_IDS = [80001];

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
  },
};

export async function setProvider(web3Connection: any) {
  const provider = new ethers.providers.Web3Provider(web3Connection);
  const signer = provider.getSigner();
  const account = await signer.getAddress();
  const { chainId } = await provider.getNetwork();
  const contractMapping = contractMappingForChainId(chainId);
  if (contractMapping) {
    const registrar = new ethers.Contract(
      contractMapping.registrar,
      CheqRegistrar.abi,
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
    };
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

type ModuleData = DirectPayData | ReversibleReleaseData | MilestonesData;

export interface WriteProps {
  currency: string;
  amount: number;
  module: ModuleData;
}

export async function write({ module, ...props }: WriteProps) {
  switch (module.moduleName) {
    case "direct":
      return await writeDirectPay({ module, ...props });
    case "reversibleRelease":
      return await writeReversibleRelease({ module, ...props });
    case "milestones":
      return writeMilestones({ module, ...props });
  }
}

interface FundProps {
  cheqId: string;
}

export async function fund({ cheqId }: FundProps) {
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
      cheq: cheqId,
    },
  });

  const nota = data["data"]["cheqs"][0];
  const amount = BigNumber.from(nota.moduleData.amount);

  switch (nota.moduleData.__typename) {
    case "DirectPayData":
      return await fundDirectPay({
        cheqId,
        amount,
        tokenAddress: nota.erc20.id,
      });
    case "ReversiblePaymentData":
      return await fundReversibleRelease({
        cheqId,
        amount,
        tokenAddress: nota.erc20.id,
      });
  }
}

interface CashPaymentProps {
  cheqId: string;
  type: "reversal" | "release";
}

export async function cash({ cheqId, type }: CashPaymentProps) {
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
      cheq: cheqId,
    },
  });

  const nota = data["data"]["cheqs"][0];
  const amount = BigNumber.from(nota.moduleData.amount);

  switch (nota.moduleData.__typename) {
    case "ReversiblePaymentData":
      return await cashReversibleRelease({
        cheqId,
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

export default {
  approveToken,
  write,
  fund,
  cash,
  sendBatchPayment,
  sendBatchPaymentFromCSV,
  getNotasQueryURL,
};
