import {
  Approval as ApprovalEvent,
  ApprovalForAll as ApprovalForAllEvent,
  BatchMetadataUpdate as BatchMetadataUpdateEvent,
  Cashed as CashedEvent,
  ContractURIUpdated as ContractURIUpdatedEvent,
  Funded as FundedEvent,
  MetadataUpdate as MetadataUpdateEvent,
  ModuleWhitelisted as ModuleWhitelistedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  TokenWhitelisted as TokenWhitelistedEvent,
  Transfer as TransferEvent,
  Transferred as TransferredEvent,
  Written as WrittenEvent
} from "../generated/NotaRegistrar/NotaRegistrar"
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
} from "../generated/schema"

export function handleApproval(event: ApprovalEvent): void {
  let entity = new Approval(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.owner = event.params.owner
  entity.approved = event.params.approved
  entity.tokenId = event.params.tokenId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleApprovalForAll(event: ApprovalForAllEvent): void {
  let entity = new ApprovalForAll(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.owner = event.params.owner
  entity.operator = event.params.operator
  entity.approved = event.params.approved

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleBatchMetadataUpdate(
  event: BatchMetadataUpdateEvent
): void {
  let entity = new BatchMetadataUpdate(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity._fromTokenId = event.params._fromTokenId
  entity._toTokenId = event.params._toTokenId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleCashed(event: CashedEvent): void {
  let entity = new Cashed(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.casher = event.params.casher
  entity.notaId = event.params.notaId
  entity.to = event.params.to
  entity.amount = event.params.amount
  entity.cashData = event.params.cashData
  entity.moduleFee = event.params.moduleFee
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleContractURIUpdated(event: ContractURIUpdatedEvent): void {
  let entity = new ContractURIUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleFunded(event: FundedEvent): void {
  let entity = new Funded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.funder = event.params.funder
  entity.notaId = event.params.notaId
  entity.amount = event.params.amount
  entity.instant = event.params.instant
  entity.fundData = event.params.fundData
  entity.moduleFee = event.params.moduleFee
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleMetadataUpdate(event: MetadataUpdateEvent): void {
  let entity = new MetadataUpdate(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity._tokenId = event.params._tokenId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleModuleWhitelisted(event: ModuleWhitelistedEvent): void {
  let entity = new ModuleWhitelisted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.user = event.params.user
  entity.module = event.params.module
  entity.isAccepted = event.params.isAccepted
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTokenWhitelisted(event: TokenWhitelistedEvent): void {
  let entity = new TokenWhitelisted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.caller = event.params.caller
  entity.token = event.params.token
  entity.accepted = event.params.accepted
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTransfer(event: TransferEvent): void {
  let entity = new Transfer(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.from = event.params.from
  entity.to = event.params.to
  entity.tokenId = event.params.tokenId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTransferred(event: TransferredEvent): void {
  let entity = new Transferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tokenId = event.params.tokenId
  entity.from = event.params.from
  entity.to = event.params.to
  entity.moduleFee = event.params.moduleFee
  entity.fundData = event.params.fundData
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleWritten(event: WrittenEvent): void {
  let entity = new Written(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.caller = event.params.caller
  entity.notaId = event.params.notaId
  entity.owner = event.params.owner
  entity.instant = event.params.instant
  entity.currency = event.params.currency
  entity.escrowed = event.params.escrowed
  entity.timestamp = event.params.timestamp
  entity.moduleFee = event.params.moduleFee
  entity.module = event.params.module
  entity.moduleData = event.params.moduleData

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
