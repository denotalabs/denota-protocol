import { BigNumber, ethers } from "ethers";
import { state, tokenAddressForCurrency } from "..";

export interface ReversibleReleaseData {
  moduleName: "ReversibleRelease";
  type: "invoice" | "payment";
  creditor: string;
  debitor: string;
  inspector?: string;
  notes?: string;
  file?: File;
  ipfsHash?: string;
  imageHash?: string;
}

export interface WriteReversibleReleaseyProps {
  currency: string;
  amount: number;
  module: ReversibleReleaseData;
}

export async function writeReversiblePay({
  module,
  amount,
  currency,
}: WriteReversibleReleaseyProps) {
  const { imageHash, ipfsHash, type, creditor, debitor, inspector } = module;
  const notaInspector = inspector ?? debitor;

  const amountWei = ethers.utils.parseEther(String(amount));

  const owner = creditor;
  const receiver = type === "invoice" ? debitor : creditor;

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "address", "uint256", "string", "string"],
    [
      receiver,
      notaInspector,
      state.blockchainState.account,
      amountWei,
      ipfsHash ?? "",
      imageHash ?? "",
    ]
  );
  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000" &&
    module.type === "payment"
      ? amountWei
      : BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    module.type === "invoice" ? 0 : amountWei, //escrowed
    0, //instant
    owner, //owner
    state.blockchainState.reversibleReleaseAddress, //module
    payload, //moduleWriteData
    { value: msgValue }
  );
  const receipt = await tx.wait();
  return receipt.transactionHash as string;
}
