import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type CashBeforeDateDripStatus = "claimable" | "awaiting_claim" | "claimed" | "expired" | "returnable" | "returned" | "locked";

export interface CashBeforeDateDripData {
  moduleName: "cashBeforeDateDrip";
  status: CashBeforeDateDripStatus;

  expirationDate: number;
  dripAmount: number;
  dripPeriod: number;
  externalURI?: string;
  imageURI?: string;
}

export interface WriteCashBeforeDateDripProps {
  currency: DenotaCurrency;
  amount: number;
  instant: number;
  owner: string;
  moduleData: CashBeforeDateDripData;
}

export async function writeCashBeforeDateDrip({
  currency,
  amount,
  instant,
  owner,
  moduleData,
}: WriteCashBeforeDateDripProps) {
  const { expirationDate, dripAmount, dripPeriod, externalURI, imageURI } = moduleData;

  const amountWei = ethers.utils.parseUnits(
    String(amount),
    tokenDecimalsForCurrency(currency)
  );

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "uint256", "uint256", "string", "string"],
    [expirationDate, dripAmount, dripPeriod, externalURI ?? "", imageURI ?? ""]
  );
  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue = BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    amountWei, //escrowed
    instant, //instant
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

export interface CashCashBeforeDateDripProps {
  to: string;
  notaId: string;
  amount: BigNumber;
}

export async function cashCashBeforeDateDrip({
  notaId,
  amount,
  to,
}: CashCashBeforeDateDripProps) {
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

export function decodeCashBeforeDateDripData(data: string) {
  let coder = new ethers.utils.AbiCoder();
  const decoded = coder.decode(
    ["uint256", "uint256", "uint256", "string", "string"],
    data
  );
  return {
    cashBeforeDate: decoded[0], 
    dripAmount: decoded[1], 
    dripPeriod: decoded[2], 
    externalURI: decoded[3],
    imageURI: decoded[4],
  };
}


export function getCashBeforeDateDripData(account: any, nota: any, hookBytes: string): CashBeforeDateDripData {
  let decoded = decodeCashBeforeDateDripData(hookBytes);
  let status;

  let lastDrip = 0;
  let dripAmount = decoded.dripAmount;
  let dripPeriod = decoded.dripPeriod;
  let cashBeforeDate = decoded.cashBeforeDate * 1000;

  if (cashBeforeDate < Date.now()) { // Expired for owner
    if (nota.sender.id == account.toLowerCase()) {
      if (nota.escrow != 0) {
        status = "returnable";
      } else {
        status = "returned";
      }
    } else {
      status = "expired";
    }
  } else if (lastDrip + dripPeriod <= Date.now()) {
    if (nota.owner.id == account.toLowerCase()) {
      if (nota.escrow > dripAmount) {
        status = "claimable";
      } else {
        status = "locked";
      }
    } else {
      if (nota.escrow > dripAmount) {
        status = "awaiting_claim";
      } else {
        status = "locked";
      }
    }
  } else {
    status = "locked";
  }

  return {
    moduleName: "cashBeforeDateDrip",
    status: status as CashBeforeDateDripStatus,
    expirationDate: cashBeforeDate,
    dripAmount: dripAmount,
    dripPeriod: dripPeriod,
    externalURI: decoded.externalURI,
    imageURI: decoded.imageURI,
  }
}