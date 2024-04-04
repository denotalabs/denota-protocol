import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  Nota,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type DirectPayStatus = "paid";

export interface DirectSendData {
  moduleName: "directSend";
  status: DirectPayStatus;
  writeBytes: string; // Unformatted writeBytes
  externalURI?: string;
  imageURI?: string;
}

export interface WriteDirectSendProps {
  currency: DenotaCurrency;
  amount: number;
  owner: string;
  moduleData: DirectSendData;
}

export async function writeDirectSend({
  currency,
  amount,
  owner,
  moduleData,
}: WriteDirectSendProps) {
  const { externalURI, imageURI } = moduleData;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["string", "string"],
    [externalURI ?? "", imageURI ?? ""]
  );

  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    0, //escrowed
    amountWei, //instant
    owner,
    state.blockchainState.contractMapping.directSend,
    payload
  );
  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}

export function decodeDirectSendData(data: string) {
  let coder = new ethers.utils.AbiCoder();
  const decoded = coder.decode(
    ["string", "string"],
    data
  );
  return {
    externalUrl: decoded[0],
    imageUrl: decoded[1],
  };
}

export function getDirectSendData(account: any, nota: Nota, writeBytes: string): DirectSendData{
  const decoded = decodeDirectSendData(writeBytes);

  return {
    moduleName: "directSend",
    status: "paid" as DirectPayStatus,
    writeBytes: writeBytes,
    externalURI: decoded.externalUrl,
    imageURI: decoded.imageUrl,
  }
}