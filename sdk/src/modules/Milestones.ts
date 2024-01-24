import { BigNumber, ethers } from "ethers";
import { notaIdFromLog, state, tokenAddressForCurrency } from "..";

export interface MilestonesData {
  moduleName: "milestones";
  type: "invoice" | "payment";
  worker: string;
  client: string;
  milestones: number[];
}

export interface MilestoneProps {
  currency: string;
  amount: number;
  ipfsHash?: string;
  module: MilestonesData;
}

export async function writeMilestones({
  module,
  amount,
  currency,
  ipfsHash,
}: MilestoneProps) {
  const { milestones, client, worker, type } = module;

  const receiver = type === "invoice" ? client : worker;

  const amountWei = ethers.utils.parseEther(String(amount));

  const payload = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "bytes32", "uint256[]"],
    [receiver, state.blockchainState.account, ipfsHash ?? "", milestones]
  );

  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const owner = worker;

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000" &&
    module.type === "payment"
      ? amountWei
      : BigNumber.from(0);

  const tx = await state.blockchainState.registrar?.write(
    tokenAddress, //currency
    module.type === "invoice" ? 0 : amountWei, //escrowed
    0, //instant
    owner,
    state.blockchainState.contractMapping.milestones,
    payload,
    { value: msgValue }
  );

  const receipt = await tx.wait();
  return {
    txHash: receipt.transactionHash as string,
    notaId: notaIdFromLog(receipt),
  };
}
