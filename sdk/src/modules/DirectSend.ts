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

  // TODO: handle other deciamls correctly
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

export function getDirectSendData(account: any, nota: any, hookBytes: string): DirectSendData{
  const decoded = decodeDirectSendData(hookBytes);

  return {
    moduleName: "directSend",
    status: "paid" as DirectPayStatus,
    externalURI: decoded.externalUrl,
    imageURI: decoded.imageUrl,
  }
}