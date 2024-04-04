import { BigNumber, ethers } from "ethers";
import {
  DenotaCurrency,
  Nota,
  notaIdFromLog,
  state,
  tokenAddressForCurrency,
  tokenDecimalsForCurrency,
} from "..";

export type CashBeforeDateDripStatus = "claimable" | "awaiting_claim" | "claimed" | "expired" | "returnable" | "returned" | "locked";

export interface CashBeforeDateDripData {
  moduleName: "cashBeforeDateDrip";
  status: CashBeforeDateDripStatus;
  writeBytes: string; // Unformatted writeBytes
  lastDrip: Date;
  expirationDate: Date;
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

// TODO default set automatic=false and if true then use state.blockchainState.account to assume what amount is being cashed. But what about the Nota's state too?
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


export function getCashBeforeDateDripData(account: any, nota: Nota, writeBytes: string): CashBeforeDateDripData {
  let decoded = decodeCashBeforeDateDripData(writeBytes);
  
  let lastDrip = (nota.cashes != undefined && nota.cashes.length > 0) ? Number(nota.cashes[nota.cashes.length - 1].transaction.timestamp) * 1000 : 0;
  let dripAmount = decoded.dripAmount;
  let dripPeriod = Number(decoded.dripPeriod) * 1000;  // In milliseconds
  let expirationDate = Number(decoded.cashBeforeDate) * 1000;  // In milliseconds

  let status;
  if (nota.cashes !== null && nota.cashes.length > 0 && nota.cashes.some(cash => cash.amount.gt(0))) {  // Has been cashed before
    const wentToOwner = nota.cashes.some(cash => cash.to === nota.owner.toLowerCase());
    if (wentToOwner) {  // At least some went to the owner
      if (nota.escrowed.isZero()) {  // Can be any combination of released, returned, or claimed if no escrow
        status = nota.cashes[nota.cashes.length-1].to == nota.sender ? "returned" : "claimed";  // TODO partial_claim if last cash was to back sender
      } else if (expirationDate < Date.now()) {  // Claim period has ended for remaining escrow
        status = account === nota.sender.toLowerCase() ? "releasable" : "awaiting_release";  // If sender they can return
      } else {  // Claim period is ongoing for remaining escrow
        if (account === nota.owner.toLowerCase()) {
          status = (lastDrip + dripPeriod) <= Date.now() ? "claimable" : "locked";  // If owner then they can claim
        } else {  // Account is someone else
          status = (lastDrip + dripPeriod) <= Date.now() ? "awaiting_claim" : "locked";
        }
      }
    } else {  // Cash went to sender (since can only release to owner or sender)
      if (nota.escrowed.isZero()) {  // No escrow left
        status = "returned";
      } else {  // Sender has escrow left
        status = account == nota.sender ? "returnable" : "awaiting_release";
      }
    }
  } else {  // No one has cashed yet
    if (expirationDate < Date.now()) {  // Claim period has ended
      status = account === nota.sender.toLowerCase() ? "releasable" : "awaiting_release";
    } else {  // Claim period is ongoing
      if (account === nota.owner.toLowerCase()) {  // Account is owner
        status = (lastDrip + dripPeriod) <= Date.now() ? "claimable" : "locked";
      } else {  // Account is someone else
        status = (lastDrip + dripPeriod) <= Date.now() ? "awaiting_claim" : "locked";
      }
    }
  }

  return {
    moduleName: "cashBeforeDateDrip",
    status: status as CashBeforeDateDripStatus,
    writeBytes: writeBytes,
    lastDrip: new Date(lastDrip),
    expirationDate: new Date(expirationDate),
    dripAmount: dripAmount,
    dripPeriod: dripPeriod,
    externalURI: decoded.externalURI,
    imageURI: decoded.imageURI,
  }
}