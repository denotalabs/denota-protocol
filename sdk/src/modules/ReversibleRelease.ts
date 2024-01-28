import { BigNumber, ethers } from "ethers";
import { notaIdFromLog, state, tokenAddressForCurrency } from "..";

export interface ReversibleReleaseData {
  moduleName: "reversibleRelease";
  payee: string;
  payer: string;
  inspector?: string;
}

export interface WriteReversibleReleaseyProps {
  currency: string;
  amount: number;
  externalUrl?: string;
  imageUrl?: string;
  module: ReversibleReleaseData;
}

export async function writeReversibleRelease({
  module,
  amount,
  currency,
  imageUrl,
  externalUrl,
}: WriteReversibleReleaseyProps) {
  const { payee, payer, inspector } = module;
  const notaInspector = inspector ? inspector : payer;

  // TODO: handle other deciamls correctly
  const amountWei = ethers.utils.parseUnits(String(amount), 6);

  const owner = payee;

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "string", "string"],
    [notaInspector, externalUrl ?? "", imageUrl ?? ""]
  );
  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000"
      ? amountWei
      : BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    amountWei, //escrowed
    0, //instant
    owner, //owner
    state.blockchainState.reversibleReleaseAddress, //module
    payload, //moduleWriteData
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}

export interface FundReversibleReleaseyProps {
  notaId: string;
  amount: BigNumber;
  tokenAddress: string;
}

export async function fundReversibleRelease({
  notaId,
  amount,
  tokenAddress,
}: FundReversibleReleaseyProps) {
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
    amount, // escrow
    0, // instant
    payload,
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return receipt.transactionHash as string;
}

export interface CashReversibleReleaseyProps {
  creditor: string;
  debtor: string;
  notaId: string;
  amount: BigNumber;
  type: "reversal" | "release";
}

export async function cashReversibleRelease({
  creditor,
  debtor,
  notaId,
  type,
  amount,
}: CashReversibleReleaseyProps) {
  const to = type === "release" ? creditor : debtor;

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address"],
    [state.blockchainState.account]
  );

  const tx = await state.blockchainState.registrar?.cash(
    notaId,
    amount,
    to,
    payload
  );
  const receipt = await tx.wait();
  return receipt.transactionHash as string;
}
