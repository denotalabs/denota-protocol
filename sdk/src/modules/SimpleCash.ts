import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type SimpleCashStatus = "claimable" | "awaiting_claim" | "claimed";

export interface SimpleCashData {
  moduleName: "simpleCash";
  status: SimpleCashStatus;
  payee: string;
  payer: string;
}

export interface WriteSimpleCashProps {
  currency: DenotaCurrency;
  amount: number;
  externalUrl?: string;
  imageUrl?: string;
  module: SimpleCashData;
}

export async function writeSimpleCash({
  module,
  amount,
  currency,
  imageUrl,
  externalUrl,
}: WriteSimpleCashProps) {
  const { payee, payer } = module;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const owner = payee;

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["string", "string"],
    [externalUrl ?? "", imageUrl ?? ""]
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

export function decodeSimpleCashData(data: string) {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    ["string", "string"],
    data
  );
  return {
    externalUrl: decoded[0],
    imageUrl: decoded[1],
  };
}

export function simpleCashStatus(account: any, nota: any, hookBytes: string){
  let coder = new ethers.utils.AbiCoder();
  let status;
  const decoded = coder.decode(["string", "string"], hookBytes);
  
  nota = Object.assign({}, nota, {
    uri: decoded[0],
    imageURI: decoded[1],
  });

  if (nota.cashes.length > 0) {
    status = "claimed";
  } else if (nota.owner.id === account.toLowerCase()) {
    status = "claimable";
  } else {
    status = "awaiting_claim";
  }

  return status;
}