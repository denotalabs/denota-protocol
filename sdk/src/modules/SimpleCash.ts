import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export interface SimpleCashData {
  moduleName: "simpleCash";
  payee: string;
  payer: string;
}

export interface WriteSimpleCashProps {
  currency: DenotaCurrency;
  amount: number;
  module: SimpleCashData;
}

export async function writeSimpleCash({
  module,
  amount,
  currency,
}: WriteSimpleCashProps) {
  const { payee, payer } = module;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const owner = payee;

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [state.blockchainState.account]
  );
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
  notaId: string;
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
