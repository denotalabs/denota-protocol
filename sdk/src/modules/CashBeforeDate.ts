import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  Nota,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type CashBeforeDateStatus = "claimable" | "awaiting_claim" | "claimed" | "expired" | "returnable" | "returned";

export interface CashBeforeDateData {
  moduleName: "cashBeforeDate";
  status: CashBeforeDateStatus;
  writeBytes: string; // Unformatted writeBytes
  cashBeforeDate: Date;
  externalURI?: string;
  imageURI?: string;
}

export interface WriteCashBeforeDateProps {
  currency: DenotaCurrency;
  amount: BigNumber;
  instant: BigNumber;
  owner: string;
  moduleData: CashBeforeDateData;
}

export async function writeCashBeforeDate({
  currency,
  amount,
  instant,
  owner,
  moduleData
}: WriteCashBeforeDateProps) {
  const { cashBeforeDate, externalURI, imageURI } = moduleData;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "string", "string"],
    [cashBeforeDate, externalURI ?? "", imageURI ?? ""]
  );
  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue = BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    amountWei, //escrowed
    0, //instant
    owner, //owner
    state.blockchainState.contractMapping.cashBeforeDate, //module
    payload, //moduleWriteData
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}

export interface CashCashBeforeDateProps {
  to: string;
  notaId: BigNumber;
  amount: BigNumber;
}

export async function cashCashBeforeDate({
  notaId,
  amount,
  to,
}: CashCashBeforeDateProps) {
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

export function decodeCashBeforeDateData(data: string) {
  let coder = new ethers.utils.AbiCoder();
  const decoded = coder.decode(
    ["uint256", "string", "string"],
    data
  );
  return {
    cashBeforeDate: decoded[0],
    externalURI: decoded[1],
    imageURI: decoded[2],
  };
}

export function getCashBeforeDateData(account: any, nota: Nota, writeBytes: string): CashBeforeDateData{
  let decoded = decodeCashBeforeDateData(writeBytes);

  let expirationDate = decoded.cashBeforeDate * 1000;

  let status;
  if (nota.cashes !== null && nota.cashes.length > 0 && nota.cashes.some(cash => cash.amount.gt(0))) {
    const wentToOwner = nota.cashes.some(cash => cash.to === nota.owner.toLowerCase());
    if (wentToOwner) {
      status = "claimed";  // Could be partially claimed
    } else {
      status = "returned";
    }
  } else if (expirationDate >= Date.now()) {
    if (nota.owner === account.toLowerCase()) {
      status = "claimable";
    } else {
      status = "awaiting_claim";
    }
  } else {
    if (nota.owner === account.toLowerCase()) {
      status = "expired";
    } else {
      status = "returnable";
    }
  }

  return {
    moduleName: "cashBeforeDate",
    status: status as CashBeforeDateStatus,
    writeBytes: writeBytes,
    cashBeforeDate: new Date(expirationDate),
    externalURI: decoded.externalURI,
    imageURI: decoded.imageURI,
  }
}