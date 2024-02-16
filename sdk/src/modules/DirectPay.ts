import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export interface DirectPayData {
  moduleName: "direct";
  type: "invoice" | "payment";
  payee: string;
  notes?: string;
  file?: File;
  dueDate?: string;
}

export interface WriteDirectPayProps {
  currency: DenotaCurrency;
  amount: number;
  externalUrl?: string;
  imageUrl?: string;
  module: DirectPayData;
}

export async function writeDirectPay({
  module,
  amount,
  currency,
  imageUrl,
  externalUrl,
}: WriteDirectPayProps) {
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
    state.blockchainState.contractMapping.directPay,
    payload,
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}

export interface FundDirectPayProps {
  notaId: string;
  amount: BigNumber;
  tokenAddress: string;
}

export async function fundDirectPay({
  notaId,
  amount,
  tokenAddress,
}: FundDirectPayProps) {
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
