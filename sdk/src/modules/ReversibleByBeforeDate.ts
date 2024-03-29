import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type ReversibleByBeforeDateStatus = "releasable" | "awaiting_release" | "released" | "returned" | "claimable" | "awaiting_claim" | "claimed";

export interface ReversibleByBeforeDateData {
  moduleName: "reversibleByBeforeDate";
  status: ReversibleByBeforeDateStatus;
  writeBytes: string; // Unformatted writeBytes
  inspector: string;
  reversibleByBeforeDate: number;
  reversibleByBeforeDateFormatted: Date;
  externalURI?: string;
  imageURI?: string;
}

export interface WriteReversibleByBeforeDateProps {
  currency: DenotaCurrency;
  amount: number;
  instant: number;
  owner: string;
  moduleData: ReversibleByBeforeDateData;
}

export async function writeReversibleByBeforeDate({
  currency,
  amount,
  instant,
  owner,
  moduleData,
}: WriteReversibleByBeforeDateProps) {
  const { inspector, reversibleByBeforeDate, externalURI, imageURI } = moduleData;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "uint256", "string", "string"],
    [inspector, reversibleByBeforeDate, externalURI ?? "", imageURI ?? ""]
  );
  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue = BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    amountWei, //escrowed
    instant, //instant
    owner, //owner
    state.blockchainState.contractMapping.reversibleByBeforeDate, //module
    payload, //moduleWriteData
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}

export interface CashReversibleByBeforeDateProps {
  to: string;
  notaId: string;
  amount: BigNumber;
}

export async function cashReversibleByBeforeDate({
  notaId,
  amount,
  to,
}: CashReversibleByBeforeDateProps) {
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


export function decodeReversibleByBeforeDateData(data: string) {
  let coder = new ethers.utils.AbiCoder();
  const decoded = coder.decode(
    ["address", "uint256", "string", "string"],
    data
  );
  return {
    inspector: decoded[0],
    reversibleByBeforeDate: decoded[1],
    externalUrl: decoded[2],
    imageUrl: decoded[3],
  };
}

export function getReversibleByBeforeDateData(account: any, nota: any, writeBytes: string): ReversibleByBeforeDateData{
  let decoded = decodeReversibleByBeforeDateData(writeBytes);
  let inspector = decoded.inspector;
  let expirationDate = decoded.reversibleByBeforeDate * 1000;
  
  let status;
  if (nota.cashes.length > 0) {
    if (nota.cashes[0].to == account.toLowerCase()) {
      status = "claimed";
    } else {
      status = "returned";
    }
  } else if (expirationDate < Date.now()) {
    if (nota.owner.id === account.toLowerCase()) {
      status = "claimable";
    } else {
      status = "awaiting_claim";
    }
  } else {
    if (inspector === account.toLowerCase()) {
      status = "releasable";
    } else {
      status = "awaiting_release";
    }
  }

  return {
    moduleName: "reversibleByBeforeDate",
    status: status as ReversibleByBeforeDateStatus,
    writeBytes: writeBytes,
    inspector: inspector.toLowerCase(),
    reversibleByBeforeDate: expirationDate,
    reversibleByBeforeDateFormatted: new Date(expirationDate),
    externalURI: decoded.externalUrl,
    imageURI: decoded.imageUrl,
  }
}