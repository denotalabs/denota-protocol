import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export interface ReversibleByBeforeDateData {
  moduleName: "reversibleByBeforeDate";
  payee: string;
  payer: string;
  reversibleByBeforeDate?: number;
  inspector?: string;
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
