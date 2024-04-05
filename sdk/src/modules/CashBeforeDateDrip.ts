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
  dripAmount: BigNumber;
  dripPeriod: BigNumber;
  externalURI?: string;
  imageURI?: string;
}

export interface WriteCashBeforeDateDripProps {
  currency: DenotaCurrency;
  amount: BigNumber;
  instant: BigNumber;
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
  notaId: BigNumber;
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
  
  let lastCash = nota.cashes !== null && nota.cashes.length > 0 ? nota.cashes[nota.cashes.length - 1] : null;
  let lastDrip = lastCash !== null && lastCash.amount.isZero() ? BigNumber.from(lastCash.amount).mul(1000) : BigNumber.from(0);
  let dripAmount = BigNumber.from(decoded.dripAmount);
  let dripPeriod = BigNumber.from(decoded.dripPeriod).mul(1000);  // In milliseconds
  let expirationDate = new Date(BigNumber.from(decoded.cashBeforeDate).mul(1000).toNumber());  // Convert to BigNumber first to avoid overflow, then convert to milliseconds
  
  let notaExpired = expirationDate.getTime() < Date.now();
  let dripAvailable = lastDrip.add(dripPeriod).toNumber() <= Date.now();

  let status;
  if (nota.cashes !== null && nota.cashes.length > 0 && nota.cashes.some(cash => cash.amount.gt(0))) {  // Has been cashed before
    const wentToOwner = nota.cashes.some(cash => cash.to === nota.owner.toLowerCase());
    if (wentToOwner) {  // At least some went to the owner
      if (nota.escrowed.isZero()) {  // Can be any combination of released, returned, or claimed if no escrow
        status = nota.cashes[nota.cashes.length-1].to == nota.sender ? "returned" : "claimed";  // TODO partial_claim if last cash was to back sender
      } else if (notaExpired) {  // Claim period has ended for remaining escrow
        status = account === nota.sender.toLowerCase() ? "releasable" : "awaiting_release";  // If sender they can return
      } else {  // Claim period is ongoing for remaining escrow
        if (account === nota.owner.toLowerCase()) {
          status = dripAvailable ? "claimable" : "locked";  // If owner then they can claim
        } else {  // Account is someone else
          status = dripAvailable ? "awaiting_claim" : "locked";
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
    if (notaExpired) {  // Claim period has ended
      status = account === nota.sender.toLowerCase() ? "releasable" : "awaiting_release";
    } else {  // Claim period is ongoing
      if (account === nota.owner.toLowerCase()) {  // Account is owner
        status = dripAvailable ? "claimable" : "locked";
      } else {  // Account is someone else
        status = dripAvailable ? "awaiting_claim" : "locked";
      }
    }
  }

  return {
    moduleName: "cashBeforeDateDrip",
    status: status as CashBeforeDateDripStatus,
    writeBytes: writeBytes,
    lastDrip: new Date(lastDrip.toNumber()),
    expirationDate: new Date(expirationDate),
    dripAmount: dripAmount,
    dripPeriod: dripPeriod,
    externalURI: decoded.externalURI,
    imageURI: decoded.imageURI,
  }
}