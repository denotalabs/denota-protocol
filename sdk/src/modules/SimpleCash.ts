import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  Nota,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type SimpleCashStatus = "claimable" | "awaiting_claim" | "claimed";

export interface SimpleCashData {
  moduleName: "simpleCash";
  status: SimpleCashStatus;
  writeBytes: string; // Unformatted writeBytes
  externalURI?: string;
  imageURI?: string;
}

export interface WriteSimpleCashProps {
  currency: DenotaCurrency;
  amount: BigNumber;
  instant: BigNumber;
  owner: string;
  moduleData: SimpleCashData;
}

// TODO should instant even be a parameter here?
export async function writeSimpleCash({
  currency,
  amount,
  instant,
  owner,
  moduleData,
}: WriteSimpleCashProps) {
  const { externalURI, imageURI } = moduleData;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const payload = ethers.utils.defaultAbiCoder.encode(["string", "string"], [externalURI ?? "", imageURI ?? ""]);
  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue = BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    amountWei, //escrowed
    0, //instant
    owner, //owner
    state.blockchainState.contractMapping.simpleCash, //module
    payload, //moduleWriteData
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}

export interface CashSimpleCashProps {
  to: string;
  notaId: BigNumber;
  amount: BigNumber;
}

export async function cashSimpleCash({
  notaId,
  amount,
  to,
}: CashSimpleCashProps) {
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

export function decodeSimpleCashData(data: string) {
  let coder = new ethers.utils.AbiCoder();
  const decoded = coder.decode(
    ["string", "string"],
    data
  );
  return {
    externalURI: decoded[0],
    imageURI: decoded[1],
  };
}

export function getSimpleCashData(account: any, nota: Nota, writeBytes: string): SimpleCashData{
  const decoded = decodeSimpleCashData(writeBytes);
  
  let status;
  if (nota.escrowed.isZero()){
    status = "claimed";
  } else if (nota.owner === account.toLowerCase()){
    status = "claimable";
  } else {
    status = "awaiting_claim";
  }

  return {
    moduleName: "simpleCash",
    status: status as SimpleCashStatus,
    writeBytes: writeBytes,
    externalURI: decoded.externalURI,
    imageURI: decoded.imageURI,
  }
}