import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export interface CashBeforeDateData {
  moduleName: "cashBeforeDate";
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
