import { ethers } from "ethers";
import { contractMappingForChainId } from "./chainInfo";

export const DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";

import CheqRegistrar from "./abis/CheqRegistrar.sol/CheqRegistrar.json";

export const DENOTA_SUPPORTED_CHAIN_IDS = [80001];

interface BlockchainState {
  signer: ethers.providers.JsonRpcSigner | null;
  registrar: ethers.Contract | null;
  account: string;
  chainId: number;
  directPayAddress: string;
  registrarAddress: string;
}

interface State {
  blockchainState: BlockchainState;
}

const state: State = {
  blockchainState: {
    account: "",
    registrar: null,
    registrarAddress: "",
    signer: null,
    directPayAddress: "",
    chainId: 0,
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
      contractMapping.cheq,
      CheqRegistrar.abi,
      signer
    );
    state.blockchainState = {
      signer,
      account,
      registrarAddress: contractMapping.cheq,
      registrar,
      directPayAddress: contractMapping.directPayModule,
      chainId,
    };
  }
}

interface ApproveTokenProps {
  token: string;
  approvalAmount: number;
}

export function approveToken({}: ApproveTokenProps) {}

interface DirectPayProps {
  recipient: string;
  token: string;
  amount: number;
  note?: string;
  file?: File;
}

export function sendDirectPayment({
  recipient,
  token,
  amount,
  note,
  file,
}: DirectPayProps) {}

export function sendDirectPayInvoice({
  recipient,
  token,
  amount,
  note,
  file,
}: DirectPayProps) {}

interface FundDirectPayProps {
  cheqId: number;
}

export function fundDirectPayInvoice({}: FundDirectPayProps) {}

interface ReversiblePaymentProps {
  recipient: string;
  token: string;
  amount: number;
  note?: string;
  file?: File;
  inspectionPeriod: number;
  fundedPercentage: number;
}

export function sendReversiblePayent({}: ReversiblePaymentProps) {}

export function sendReversibleInvoice({}: ReversiblePaymentProps) {}

interface ReversePaymentProps {
  cheqId: number;
}

export function reversePayment({}: ReversePaymentProps) {}

interface Milestone {
  amount: number;
  note: string;
  targetCompletion: Date;
}

interface MilestoneProps {
  milestones: Milestone[];
  token: string;
  recipient: string;
  file: File;
}

export function sendMilestoneInvoice({}: MilestoneProps) {}

interface MilestonePaymentProps extends MilestoneProps {
  fundedMilestones: number[];
}

export function sendMilestonePayment({}: MilestonePaymentProps) {}

export function fetchNotas(query: string) {}
