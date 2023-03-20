import { BigNumber, ethers } from "ethers";
import { state, tokenAddressForCurrency } from "..";

export interface DirectPayData {
  moduleName: "Direct";
  type: "invoice" | "payment";
  creditor: string;
  debitor: string;
  notes?: string;
  file?: File;
  ipfsHash?: string;
  imageHash?: string;
  dueDate?: string;
}

export interface WriteDirectPayProps {
  currency: string;
  amount: number;
  module: DirectPayData;
}

export async function writeDirectPay({
  module,
  amount,
  currency,
}: WriteDirectPayProps) {
  const { dueDate, imageHash, ipfsHash } = module;
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

  let receiver;
  const owner = module.creditor;
  if (module.type === "invoice") {
    receiver = module.debitor;
  } else {
    receiver = module.creditor;
  }
  const amountWei = ethers.utils.parseEther(String(amount));

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "uint256", "uint256", "address", "string", "string"],
    [
      receiver,
      amountWei,
      dueTimestamp,
      state.blockchainState.account,
      imageHash ?? "",
      ipfsHash ?? "",
    ]
  );

  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000" &&
    module.type !== "invoice"
      ? amountWei
      : BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    0, //escrowed
    module.type === "invoice" ? 0 : amountWei, //instant
    owner,
    state.blockchainState.directPayAddress,
    payload
  );
  const receipt = await tx.wait();
  return receipt.transactionHash as string;
}
