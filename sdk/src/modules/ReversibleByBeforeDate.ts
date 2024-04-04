import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  Nota,
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
  reversibleByBeforeDate: Date;
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

export function getReversibleByBeforeDateData(account: any, nota: Nota, writeBytes: string): ReversibleByBeforeDateData{
  let decoded = decodeReversibleByBeforeDateData(writeBytes);
  let inspector = decoded.inspector.toLowerCase();
  let expirationDate = decoded.reversibleByBeforeDate * 1000;
  
  let status;
  if (nota.cashes !== null && nota.cashes.length > 0 && nota.cashes.some(cash => cash.amount.gt(0))) {  // Has been cashed before
    const wentToOwner = nota.cashes.some(cash => cash.to === nota.owner.toLowerCase());
    if (wentToOwner) {
      if (nota.escrowed.isZero()) {  // Can be any combination of released, returned, or claimed if no escrow
        status = "released";
      } else if (expirationDate < Date.now()) { // Inspection has ended for remaining escrow
        status = account === inspector ? "awaiting_claim" : "claimable";
      } else {  // Inspection is ongoing for remaining escrow
        status = account === inspector ? "releasable" : "awaiting_release";
      }
    } else {  // Cash went to sender (since inspector can only release to owner or sender)
      status = "returned";
    }
  } else {  // No one has cashed yet
    if (expirationDate < Date.now()) {  // Inspection has ended
      status = account === inspector ? "awaiting_claim" : "claimable";
    } else {  // Inspection is ongoing
      status = account === inspector ? "releasable" : "awaiting_claim";
    }
  }

  return {
    moduleName: "reversibleByBeforeDate",
    status: status as ReversibleByBeforeDateStatus,
    writeBytes: writeBytes,
    inspector: inspector.toLowerCase(),
    reversibleByBeforeDate: new Date(expirationDate),
    externalURI: decoded.externalUrl,
    imageURI: decoded.imageUrl,
  }
}