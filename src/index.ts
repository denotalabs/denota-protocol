import { BigNumber, ethers } from "ethers";
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
  imageHash?: string;
  dueDate?: string;
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
  const { dueDate, imageHash, ipfsHash } = module;
  const utcOffset = new Date().getTimezoneOffset();

  let dueTimestamp: number;

  if (dueDate) {
    dueTimestamp = Date.parse(`${dueDate}T00:00:00Z`) / 1000 + utcOffset * 60;
  } else {
    const d = new Date();
    const today = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
      .toISOString()
      .slice(0, 10);
    dueTimestamp = Date.parse(`${today}T00:00:00Z`) / 1000 + utcOffset * 60;
  }

  let receiver;
  const owner = module.creditor;
  if (module.type === "invoice") {
    receiver = module.debitor;
  } else {
    receiver = module.creditor;
  }
  const amountWei = ethers.utils.parseEther(String(amount));

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "uint256", "uint256", "address", "string", "string"],
    [
      receiver,
      amountWei,
      dueTimestamp,
      state.blockchainState.account,
      imageHash,
      ipfsHash,
    ]
  );

  const token = tokenForCurrency(currency);
  const tokenAddress = token?.address ?? "";

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000" &&
    module.type !== "invoice"
      ? amountWei
      : BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    0, //escrowed
    module.type === "invoice" ? 0 : amountWei, //instant
    owner,
    state.blockchainState.directPayAddress,
    payload
  );
  const receipt = await tx.wait();
  return receipt.transactionHash;
}

interface FundProps {
  cheqId: string;
}

export async function fund({ cheqId }: FundProps) {}

interface ReversePaymentProps {
  cheqId: string;
}

export async function reverse({ cheqId }: ReversePaymentProps) {}

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
