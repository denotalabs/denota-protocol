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
  payee: string;
  payer: string;
  cashBeforeDate: number;
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
  const decoded = ethers.utils.defaultAbiCoder.decode(
    ["uint256", "string", "string"],
    data
  );
  return {
    cashBeforeDate: decoded[0],
    externalUrl: decoded[0],
    imageUrl: decoded[1],
  };
}

export function cashBeforeDateStatus(account: any, nota: any, hookBytes: string){
  let coder = new ethers.utils.AbiCoder();
  let status;
  let decoded = coder.decode(["uint256", "string", "string"], hookBytes);
  let expirationDate = decoded[0];

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
  return status;
}