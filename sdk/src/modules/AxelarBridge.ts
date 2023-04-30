import {
  AxelarQueryAPI,
  CHAINS,
  Environment,
} from "@axelar-network/axelarjs-sdk";
import { BigNumber, ethers } from "ethers";
import { state, tokenAddressForCurrency } from "..";
import { ContractAddressMapping } from "../chainInfo";

export interface AxelarBridgeData {
  moduleName: "crosschain";
  creditor: string;
}

export interface AxelarBridgeProps {
  currency: string;
  amount: number;
  ipfsHash?: string;
  imageUrl?: string;
  module: AxelarBridgeData;
}

export async function writeCrossChainNota({
  module,
  amount,
  currency,
  imageUrl,
  ipfsHash,
}: AxelarBridgeProps) {
  const { creditor } = module;

  const amountWei = ethers.utils.parseEther(String(amount));

  const api = new AxelarQueryAPI({ environment: Environment.TESTNET });
  const axelarFeeString = await api.estimateGasFee(
    CHAINS.TESTNET["CELO"],
    CHAINS.TESTNET["POLYGON"],
    "CELO",
    300000, // gas limit
    1.2 // gas multiplier
  );

  const axelarFee = BigNumber.from(axelarFeeString);

  const tokenAddress = tokenAddressForCurrency(currency) ?? "";

  const msgValue =
    tokenAddress === "0x0000000000000000000000000000000000000000"
      ? amountWei.add(axelarFee)
      : axelarFee;

  const tx = await state.blockchainState.axelarBridgeSender?.createRemoteNota(
    tokenAddress, //currency
    amountWei, //amount
    creditor, //owner
    ipfsHash,
    imageUrl,
    "Polygon", //destinationChain
    ContractAddressMapping.mumbai.bridgeReceiver,
    { value: msgValue }
  );
  const receipt = await tx.wait();
  const txHash = receipt.transactionHash as string;
  // Nota hasn't been minted yet so use tx hash as temp nota id
  return { txHash, notaId: txHash };
}
