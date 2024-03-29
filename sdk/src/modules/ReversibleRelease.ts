import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type ReversibleReleaseStatus = "releasable" | "awaiting_release" | "returned" | "released";

export interface ReversibleReleaseData {
  moduleName: "reversibleRelease";
  status: ReversibleReleaseStatus;

  inspector: string;
  externalURI?: string;
  imageURI?: string;
}

export interface WriteReversibleReleaseyProps {
  currency: DenotaCurrency;
  amount: number;
  instant: number;
  owner: string;
  moduleData: ReversibleReleaseData;
}

export async function writeReversibleRelease({
  currency,
  amount,
  instant,
  owner,
  moduleData
}: WriteReversibleReleaseyProps) {
  const { inspector, externalURI, imageURI } = moduleData;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "string", "string"],
    [inspector, externalURI ?? "", imageURI ?? ""]
  );
  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue = BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    amountWei, //escrowed
    instant,
    owner,
    state.blockchainState.contractMapping.reversibleRelease, //module
    payload, // moduleWriteData
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}

export interface FundReversibleReleaseyProps {
  notaId: string;
  amount: BigNumber;
  tokenAddress: string;
}

export async function fundReversibleRelease({
  notaId,
  amount,
  tokenAddress,
}: FundReversibleReleaseyProps) {
  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [state.blockchainState.account]
  );

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000"
      ? amount
      : BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.fund(
    notaId,
    amount, // escrow
    0, // instant
    payload,
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return receipt.transactionHash as string;
}

export interface CashReversibleReleaseyProps {
  to: string;
  notaId: string;
  amount: BigNumber;
}

export async function cashReversibleRelease({
  notaId,
  amount,
  to,
}: CashReversibleReleaseyProps) {
  const payload = ethers.utils.defaultAbiCoder.encode([], []);
  const tx = await state.blockchainState.registrar?.cash(
    notaId,
    amount,
    to,
    payload
  );
  const receipt = await tx.wait();
  return receipt.transactionHash as string;
}

export function decodeReversibleReleaseData(data: string) {
  let coder = new ethers.utils.AbiCoder();
  const decoded = coder.decode(
    ["address", "string", "string"],
    data
  );

  return {
    inspector: decoded[0],
    externalURI: decoded[1],
    imageURI: decoded[2],
  };
}

export function getReversibleReleaseData(account: any, nota: any, hookBytes: string): ReversibleReleaseData {
  let inspector = "0x";
  let status = "returnable";
  let externalURI = "";
  let imageURI = "";

  try {
    let decoded = decodeReversibleReleaseData(hookBytes);

    inspector = decoded.inspector;
    externalURI = decoded.externalURI;
    imageURI = decoded.imageURI
    
    status;
    if (nota.cashes.length > 0) {
      // TODO Need to know if the `to` went to the `owner` at the time it was released
      //// Need to check transfers and if >0 check if the cash timestamp was before it
      if (nota.cashes[0].to === nota.owner.id) {
        status = "released";
      } else {
        status = "returned";
      }
    } else {
      if (inspector === account.toLowerCase()) {
        status = "releasable";
      } else {
        status = "awaiting_release";
      }
    }
  } catch {
    console.log(nota);
  }
  return {
    moduleName: "reversibleRelease",
    status: status as ReversibleReleaseStatus,
    inspector: inspector.toLowerCase(),
    externalURI: externalURI,
    imageURI: imageURI,
  }
}