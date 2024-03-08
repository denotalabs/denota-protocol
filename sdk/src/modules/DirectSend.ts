import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type DirectPayStatus = "paid";

export interface DirectSendData {
  moduleName: "directSend";
  status: DirectPayStatus;
  type: "invoice" | "payment";
  payee: string;
  notes?: string;
  file?: File;
  dueDate?: string;
}

export interface WriteDirectSendProps {
  currency: DenotaCurrency;
  amount: number;
  externalUrl?: string;
  imageUrl?: string;
  module: DirectSendData;
}

export async function writeDirectSend({
  module,
  amount,
  currency,
  imageUrl,
  externalUrl,
}: WriteDirectSendProps) {
  const { dueDate, payee } = module;
  const utcOffset = new Date().getTimezoneOffset();

  let dueTimestamp: number;

  if (dueDate) {
    dueTimestamp = Date.parse(`${dueDate}T00:00:00Z`) / 1000 + utcOffset * 60;
  } else {
    const d = new Date();
    const today = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
      .toISOString()
      .slice(0, 10);
    dueTimestamp = Date.parse(`${today}T00:00:00Z`) / 1000 + utcOffset * 60;
  }

  const owner = payee;

  // TODO: handle other deciamls correctly
  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["string", "string"],
    [externalUrl ?? "", imageUrl ?? ""]
  );

  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000" &&
    module.type === "payment"
      ? amountWei
      : BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    0, //escrowed
    module.type === "invoice" ? 0 : amountWei, //instant
    owner,
    state.blockchainState.contractMapping.DirectSend,
    payload,
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}

export interface FundDirectSendProps {
  notaId: string;
  amount: BigNumber;
  tokenAddress: string;
}

export async function fundDirectSend({
  notaId,
  amount,
  tokenAddress,
}: FundDirectSendProps) {
  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [state.blockchainState.account]
  );

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000"
      ? amount
      : BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.fund(
    notaId,
    0, // escrow
    amount, // instant
    payload,
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return receipt.transactionHash as string;
}

export function decodeDirectSendData(data: string) {
  const decoded = ethers.utils.defaultAbiCoder.decode(
    ["string", "string"],
    data
  );
  return {
    externalUrl: decoded[0],
    imageUrl: decoded[1],
  };
}

export function directSendStatus(account: any, nota: any, hookBytes: string){
  // let coder = new ethers.utils.AbiCoder();
  // const decoded = coder.decode(["string", "string"], hookBytes);

  return "paid";
}