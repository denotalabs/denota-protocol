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

  inspector: string;
  reversibleByBeforeDate: number;
  externalURI?: string;
  imageURI?: string;
}

export interface WriteReversibleByBeforeDateProps {
  currency: DenotaCurrency;
  amount: number;
  externalUrl?: string;
  imageUrl?: string;
  module: ReversibleByBeforeDateData;
}

export async function writeReversibleByBeforeDate({
  module,
  amount,
  currency,
  imageUrl,
  externalUrl,
}: WriteReversibleByBeforeDateProps) {
  const { payee, payer, reversibleByBeforeDate, inspector } = module;

  const notaInspector = inspector ? inspector : payer;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const owner = payee;

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "uint256", "string", "string"],
    [notaInspector, reversibleByBeforeDate, externalUrl ?? "", imageUrl ?? ""]
  );
  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue = BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    amountWei, //escrowed
    0, //instant
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

export function getReversibleByBeforeDateData(account: any, nota: any, hookBytes: string): ReversibleByBeforeDateData{
  let status;
  let decoded = decodeReversibleByBeforeDateData(hookBytes);
  let inspector = decoded.inspector;
  let expirationDate = decoded.reversibleByBeforeDate * 1000;

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
    status: status as getReversibleByBeforeDateData,
    inspector: inspector,
    reversibleByBeforeDate: expirationDate,
    externalURI: decoded.externalUrl,
    imageURI: decoded.imageUrl,
  }
}