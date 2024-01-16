import { ethers } from "ethers";
import { state, tokenAddressForCurrency } from "..";

export interface CsvData {
  recipient: string;
  value: number;
  token: string;
}

export interface BatchProps {
  data: CsvData[];
}

export async function BatchDisperse({ data }: BatchProps) {
  const [tokens, values, recipients] = [
    data.map((val) => tokenAddressForCurrency(val.token)),
    data.map((val) => ethers.utils.parseEther(String(val.value))),
    data.map((val) => val.recipient),
  ];

  const tx = await state.blockchainState.disperse?.disperse(
    tokens,
    recipients,
    values
  );

  const receipt = await tx.wait();
  return receipt.transactionHash;
}
