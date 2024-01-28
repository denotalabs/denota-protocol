import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  Approval,
  ApprovalForAll,
  BatchMetadataUpdate,
  Cashed,
  ContractURIUpdated,
  Funded,
  MetadataUpdate,
  ModuleWhitelisted,
  OwnershipTransferred,
  TokenWhitelisted,
  Transfer,
  Transferred,
  Written
} from "../generated/NotaRegistrar/NotaRegistrar"

export function createApprovalEvent(
  owner: Address,
  approved: Address,
  tokenId: BigInt
): Approval {
  let approvalEvent = changetype<Approval>(newMockEvent())

  approvalEvent.parameters = new Array()

  approvalEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam("approved", ethereum.Value.fromAddress(approved))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return approvalEvent
}

export function createApprovalForAllEvent(
  owner: Address,
  operator: Address,
  approved: boolean
): ApprovalForAll {
  let approvalForAllEvent = changetype<ApprovalForAll>(newMockEvent())

  approvalForAllEvent.parameters = new Array()

  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("operator", ethereum.Value.fromAddress(operator))
  )
  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("approved", ethereum.Value.fromBoolean(approved))
  )

  return approvalForAllEvent
}

export function createBatchMetadataUpdateEvent(
  _fromTokenId: BigInt,
  _toTokenId: BigInt
): BatchMetadataUpdate {
  let batchMetadataUpdateEvent = changetype<BatchMetadataUpdate>(newMockEvent())

  batchMetadataUpdateEvent.parameters = new Array()

  batchMetadataUpdateEvent.parameters.push(
    new ethereum.EventParam(
      "_fromTokenId",
      ethereum.Value.fromUnsignedBigInt(_fromTokenId)
    )
  )
  batchMetadataUpdateEvent.parameters.push(
    new ethereum.EventParam(
      "_toTokenId",
      ethereum.Value.fromUnsignedBigInt(_toTokenId)
    )
  )

  return batchMetadataUpdateEvent
}

export function createCashedEvent(
  casher: Address,
  notaId: BigInt,
  to: Address,
  amount: BigInt,
  cashData: Bytes,
  moduleFee: BigInt,
  timestamp: BigInt
): Cashed {
  let cashedEvent = changetype<Cashed>(newMockEvent())

  cashedEvent.parameters = new Array()

  cashedEvent.parameters.push(
    new ethereum.EventParam("casher", ethereum.Value.fromAddress(casher))
  )
  cashedEvent.parameters.push(
    new ethereum.EventParam("notaId", ethereum.Value.fromUnsignedBigInt(notaId))
  )
  cashedEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  cashedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  cashedEvent.parameters.push(
    new ethereum.EventParam("cashData", ethereum.Value.fromBytes(cashData))
  )
  cashedEvent.parameters.push(
    new ethereum.EventParam(
      "moduleFee",
      ethereum.Value.fromUnsignedBigInt(moduleFee)
    )
  )
  cashedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return cashedEvent
}

export function createContractURIUpdatedEvent(): ContractURIUpdated {
  let contractUriUpdatedEvent = changetype<ContractURIUpdated>(newMockEvent())

  contractUriUpdatedEvent.parameters = new Array()

  return contractUriUpdatedEvent
}

export function createFundedEvent(
  funder: Address,
  notaId: BigInt,
  amount: BigInt,
  instant: BigInt,
  fundData: Bytes,
  moduleFee: BigInt,
  timestamp: BigInt
): Funded {
  let fundedEvent = changetype<Funded>(newMockEvent())

  fundedEvent.parameters = new Array()

  fundedEvent.parameters.push(
    new ethereum.EventParam("funder", ethereum.Value.fromAddress(funder))
  )
  fundedEvent.parameters.push(
    new ethereum.EventParam("notaId", ethereum.Value.fromUnsignedBigInt(notaId))
  )
  fundedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  fundedEvent.parameters.push(
    new ethereum.EventParam(
      "instant",
      ethereum.Value.fromUnsignedBigInt(instant)
    )
  )
  fundedEvent.parameters.push(
    new ethereum.EventParam("fundData", ethereum.Value.fromBytes(fundData))
  )
  fundedEvent.parameters.push(
    new ethereum.EventParam(
      "moduleFee",
      ethereum.Value.fromUnsignedBigInt(moduleFee)
    )
  )
  fundedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return fundedEvent
}

export function createMetadataUpdateEvent(_tokenId: BigInt): MetadataUpdate {
  let metadataUpdateEvent = changetype<MetadataUpdate>(newMockEvent())

  metadataUpdateEvent.parameters = new Array()

  metadataUpdateEvent.parameters.push(
    new ethereum.EventParam(
      "_tokenId",
      ethereum.Value.fromUnsignedBigInt(_tokenId)
    )
  )

  return metadataUpdateEvent
}

export function createModuleWhitelistedEvent(
  user: Address,
  module: Address,
  isAccepted: boolean,
  timestamp: BigInt
): ModuleWhitelisted {
  let moduleWhitelistedEvent = changetype<ModuleWhitelisted>(newMockEvent())

  moduleWhitelistedEvent.parameters = new Array()

  moduleWhitelistedEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  moduleWhitelistedEvent.parameters.push(
    new ethereum.EventParam("module", ethereum.Value.fromAddress(module))
  )
  moduleWhitelistedEvent.parameters.push(
    new ethereum.EventParam(
      "isAccepted",
      ethereum.Value.fromBoolean(isAccepted)
    )
  )
  moduleWhitelistedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return moduleWhitelistedEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createTokenWhitelistedEvent(
  caller: Address,
  token: Address,
  accepted: boolean,
  timestamp: BigInt
): TokenWhitelisted {
  let tokenWhitelistedEvent = changetype<TokenWhitelisted>(newMockEvent())

  tokenWhitelistedEvent.parameters = new Array()

  tokenWhitelistedEvent.parameters.push(
    new ethereum.EventParam("caller", ethereum.Value.fromAddress(caller))
  )
  tokenWhitelistedEvent.parameters.push(
    new ethereum.EventParam("token", ethereum.Value.fromAddress(token))
  )
  tokenWhitelistedEvent.parameters.push(
    new ethereum.EventParam("accepted", ethereum.Value.fromBoolean(accepted))
  )
  tokenWhitelistedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return tokenWhitelistedEvent
}

export function createTransferEvent(
  from: Address,
  to: Address,
  tokenId: BigInt
): Transfer {
  let transferEvent = changetype<Transfer>(newMockEvent())

  transferEvent.parameters = new Array()

  transferEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return transferEvent
}

export function createTransferredEvent(
  tokenId: BigInt,
  from: Address,
  to: Address,
  moduleFee: BigInt,
  fundData: Bytes,
  timestamp: BigInt
): Transferred {
  let transferredEvent = changetype<Transferred>(newMockEvent())

  transferredEvent.parameters = new Array()

  transferredEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  transferredEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  transferredEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  transferredEvent.parameters.push(
    new ethereum.EventParam(
      "moduleFee",
      ethereum.Value.fromUnsignedBigInt(moduleFee)
    )
  )
  transferredEvent.parameters.push(
    new ethereum.EventParam("fundData", ethereum.Value.fromBytes(fundData))
  )
  transferredEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return transferredEvent
}

export function createWrittenEvent(
  caller: Address,
  notaId: BigInt,
  owner: Address,
  instant: BigInt,
  currency: Address,
  escrowed: BigInt,
  timestamp: BigInt,
  moduleFee: BigInt,
  module: Address,
  moduleData: Bytes
): Written {
  let writtenEvent = changetype<Written>(newMockEvent())

  writtenEvent.parameters = new Array()

  writtenEvent.parameters.push(
    new ethereum.EventParam("caller", ethereum.Value.fromAddress(caller))
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam("notaId", ethereum.Value.fromUnsignedBigInt(notaId))
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam(
      "instant",
      ethereum.Value.fromUnsignedBigInt(instant)
    )
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam(
      "escrowed",
      ethereum.Value.fromUnsignedBigInt(escrowed)
    )
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam(
      "moduleFee",
      ethereum.Value.fromUnsignedBigInt(moduleFee)
    )
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam("module", ethereum.Value.fromAddress(module))
  )
  writtenEvent.parameters.push(
    new ethereum.EventParam("moduleData", ethereum.Value.fromBytes(moduleData))
  )

  return writtenEvent
}
