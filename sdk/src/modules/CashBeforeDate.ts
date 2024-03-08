import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type CashBeforeDateStatus = "claimable" | "awaiting_claim" | "claimed" | "expired" | "returnable" | "returned";

export interface CashBeforeDateData {
  moduleName: "cashBeforeDate";
  status: CashBeforeDateStatus;
  cashBeforeDate: number;
  externalURI?: string;
  imageURI?: string;
}

export interface WriteCashBeforeDateProps {
  currency: DenotaCurrency;
  amount: number;
  externalUrl?: string;
  imageUrl?: string;
  module: CashBeforeDateData;
}

export async function writeCashBeforeDate({
  module,
  amount,
  currency,
  imageUrl,
  externalUrl,
}: WriteCashBeforeDateProps) {
  const { payee, payer, cashBeforeDate } = module;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const owner = payee;

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "string", "string"],
    [cashBeforeDate, externalUrl ?? "", imageUrl ?? ""]
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
  notaId: string;
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
    externalURI: decoded[0],
    imageURI: decoded[1],
  };
}

export function getCashBeforeDateData(account: any, nota: any, hookBytes: string): CashBeforeDateData{
  let decoded = decodeCashBeforeDateData(hookBytes);

  let expirationDate = decoded.cashBeforeDate * 1000;

  let status;
  if (nota.cashes.length > 0) {
    if (nota.cashes[0].to == account.toLowerCase()) {
      status = "claimed";
    } else {
      status = "returned";
    }
  } else if (expirationDate >= Date.now()) {
    if (nota.owner.id === account.toLowerCase()) {
      status = "claimable";
    } else {
      status = "awaiting_claim";
    }
  } else {
    if (nota.owner.id === account.toLowerCase()) {
      status = "expired";
    } else {
      status = "returnable";
    }
  }
  return {
    moduleName: "cashBeforeDate",
    status: status as CashBeforeDateStatus,
    cashBeforeDate: expirationDate,
    externalURI: decoded.externalURI,
    imageURI: decoded.imageURI,
  }
}