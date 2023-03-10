import { ethers } from "ethers";
import erc20 from "./abis/ERC20.sol/TestERC20.json";
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
  dai: ethers.Contract | null;
  weth: ethers.Contract | null;
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
    dai: null,
    weth: null,
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
    const dai = new ethers.Contract(contractMapping.dai, erc20.abi, signer);
    const weth = new ethers.Contract(contractMapping.weth, erc20.abi, signer);
    state.blockchainState = {
      signer,
      account,
      registrarAddress: contractMapping.cheq,
      registrar,
      directPayAddress: contractMapping.directPayModule,
      chainId,
      dai,
      weth,
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

export interface DirectPayData {
  moduleName: "Direct";
  type: "invoice" | "payment";
  creditor: string;
  debitor: string;
  notes?: string;
  file?: File;
  ipfsHash?: string;
}

export interface EscrowData {
  moduleName: "Escrow";
  inspectionPeriod: number;
}

type ModuleData = DirectPayData | EscrowData;

export interface WriteProps {
  currency: string;
  amount: number;
  module: ModuleData;
}

export async function write({ module, amount, currency }: WriteProps) {
  if (module.moduleName == "Direct") {
    const hash = await writeDirectPay({ module, amount, currency });
    return hash;
  } else {
  }
}

export interface WriteDirectPayProps {
  currency: string;
  amount: number;
  module: DirectPayData;
}

async function writeDirectPay({
  module,
  amount,
  currency,
}: WriteDirectPayProps) {
  let receiver;
  const owner = module.creditor;
  if (module.type === "invoice") {
    receiver = module.debitor;
  } else {
    receiver = module.creditor;
  }
  const amountWei = ethers.utils.parseEther(String(amount));

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "uint256", "uint256", "address", "string"],
    [
      receiver,
      amountWei,
      0,
      state.blockchainState.account,
      module.ipfsHash ?? "",
    ]
  );

  const token = tokenForCurrency(currency);
  const tokenAddress = token?.address ?? "";

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress,
    0,
    module.type === "invoice" ? 0 : amountWei,
    owner,
    state.blockchainState.directPayAddress,
    payload
  );
  const receipt = await tx.wait();
  return receipt.transactionHash;
}

// interface FundDirectPayProps {
//   cheqId: number;
// }

// export function fundDirectPayInvoice({}: FundDirectPayProps) {}

// interface ReversiblePaymentProps {
//   recipient: string;
//   token: string;
//   amount: number;
//   note?: string;
//   file?: File;
//   inspectionPeriod: number;
//   fundedPercentage: number;
// }

// export function sendReversiblePayent({}: ReversiblePaymentProps) {}

// export function sendReversibleInvoice({}: ReversiblePaymentProps) {}

// interface ReversePaymentProps {
//   cheqId: number;
// }

// export function reversePayment({}: ReversePaymentProps) {}

// interface Milestone {
//   amount: number;
//   note: string;
//   targetCompletion: Date;
// }

// interface MilestoneProps {
//   milestones: Milestone[];
//   token: string;
//   recipient: string;
//   file: File;
// }

// export function sendMilestoneInvoice({}: MilestoneProps) {}

// interface MilestonePaymentProps extends MilestoneProps {
//   fundedMilestones: number[];
// }

// export function sendMilestonePayment({}: MilestonePaymentProps) {}

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

export function fetchNotas(query: string) {}
