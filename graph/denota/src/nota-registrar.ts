import { BigInt, Address } from "@graphprotocol/graph-ts";
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
  Written, Transaction, ERC20, Account, Nota, Module
} from "../generated/schema"
// TODO update NotaRegistrar entity
// Don't currently have the number of Notas owned being tracted by account

function saveNewAccount(account: string): Account {
  const newAccount = new Account(account);
  newAccount.save();
  return newAccount;
}
function saveNewERC20(erc20: string): ERC20 {
  const newERC20 = new ERC20(erc20);
  newERC20.save();
  return newERC20;
}
function saveNewModule(module: string): Module {
  const newModule = new Module(module);
  newModule.save();
  return newModule;
}
function saveTransaction(
  transactionHexHash: string,
  // TODO figure out BigInt vs bigint literal eslint issue
  // eslint-disable-next-line @typescript-eslint/ban-types
  timestamp: BigInt,
  // eslint-disable-next-line @typescript-eslint/ban-types
  blockNumber: BigInt
): Transaction {
  // TODO not sure if the ID structure is best
  let transaction = Transaction.load(transactionHexHash); // OZ Uses this entity, what to use as its ID?
  if (transaction == null) {
    transaction = new Transaction(transactionHexHash);
    transaction.timestamp = timestamp;
    transaction.blockNumber = blockNumber;
    transaction.transactionHash = transactionHexHash;
    transaction.save();
  }
  return transaction;
}

export function handleWritten(event: WrittenEvent): void {
  const currency = event.params.currency.toHexString();
  const owner = event.params.owner.toHexString();
  const sender = event.params.caller.toHexString();
  const module = event.params.module.toHexString();
  const transactionHexHash = event.transaction.hash.toHex();

  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  let owningAccount = Account.load(owner);
  owningAccount = owningAccount == null ? saveNewAccount(owner) : owningAccount;
  let senderAccount = Account.load(sender);
  senderAccount = senderAccount == null ? saveNewAccount(sender) : senderAccount;
  let ERC20Token = ERC20.load(currency);
  ERC20Token = ERC20Token == null ? saveNewERC20(currency) : ERC20Token;
  let moduleEntity = Module.load(module);
  moduleEntity = moduleEntity == null ? saveNewModule(module) : moduleEntity;

  const nota = new Nota(event.params.notaId.toString());

  nota.erc20 = ERC20Token.id;
  nota.escrowed = event.params.escrowed;
  nota.module = moduleEntity.id;
  nota.sender = senderAccount.id;
  nota.receiver = owningAccount.id;
  nota.owner = owningAccount.id;
  // nota.imageUri = "";
  // nota.externalUri = "";
  nota.createdTransaction = transaction.id;
  // nota.moduleData = ""; // TODO attach hook specific parameters
  nota.save();

  const entity = new Written(transactionHexHash + "/" + nota.id);
  entity.caller = senderAccount.id;
  entity.nota = nota.id;
  entity.owner = owningAccount.id;
  entity.instant = event.params.instant;
  entity.currency = ERC20Token.id;
  entity.escrowed = event.params.escrowed;
  entity.moduleFee = event.params.moduleFee;
  entity.module = moduleEntity.id;
  entity.moduleData = event.params.moduleData;
  entity.transaction = transaction.id;
}

export function handleFunded(event: FundedEvent): void {
  const transactionHexHash = event.transaction.hash.toHex();
  let fromAccount = Account.load(event.params.funder.toHexString());
  fromAccount =
    fromAccount == null
      ? saveNewAccount(event.params.funder.toHexString())
      : fromAccount;
  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  // Load nota
  const notaId = event.params.notaId.toString();
  let nota = Nota.load(notaId);
  if (nota == null) {
    // SHOULDN NEVER BE THE CASE
    nota = new Nota(notaId);
    nota.save();
  }

  // Attaching hook specific parameters to the Nota
  // TODO

  let entity = new Funded(transactionHexHash + "/" + notaId);
  entity.funder = event.params.funder;
  entity.nota = nota.id;
  entity.amount = event.params.amount;
  entity.instant = event.params.instant;
  entity.fundData = event.params.fundData;
  entity.moduleFee = event.params.moduleFee;
  entity.transaction = transaction.id;

  entity.save()

  // nota.escrowed = nota.escrowed + amount;  // TODO
  // nota.save()
}

export function handleCashed(event: CashedEvent): void {
    let toAccount = Account.load(event.params.to.toHexString());
    toAccount =
      toAccount == null
        ? saveNewAccount(event.params.to.toHexString())
        : toAccount;
    const amount = event.params.amount;
    const transactionHexHash = event.transaction.hash.toHex();
    const transaction = saveTransaction(
      transactionHexHash,
      event.block.timestamp,
      event.block.number
    );
    const notaId = event.params.notaId.toString();
  
    // Load nota
    let nota = Nota.load(notaId);
    if (nota == null) {
      // SHOULDN'T BE THE CASE
      nota = new Nota(notaId);
      nota.save();
    }
  
    // if (nota.moduleData.endsWith("/escrow")) {
    //   const reversiblePayData = ReversiblePaymentData.load(nota.moduleData);
    //   if (reversiblePayData) {
    //     if (nota.owner == toAccount.id) {
    //       reversiblePayData.status = "RELEASED";
    //     } else {
    //       reversiblePayData.status = "VOIDED";
    //     }
    //     reversiblePayData.save();
    //   }
    // }
  
    // // nota.escrowed -= amount;  // TODO does this need to be done or front end handles?
    let entity = new Cashed(transactionHexHash + "/" + notaId)
    entity.casher = event.params.casher
    entity.nota = nota.id
    entity.to = event.params.to
    entity.amount = event.params.amount
    entity.cashData = event.params.cashData
    entity.moduleFee = event.params.moduleFee
    entity.transaction = transaction.id
  
    entity.save()
}

// TODO: Transfer event being fired before write event is causing problems
export function handleTransfer(event: TransferEvent): void {
  // Load event params
  const from = event.params.from.toHexString();
  const to = event.params.to.toHexString();
  const notaId = event.params.tokenId.toHexString();
  const transactionHexHash = event.transaction.hash.toHex();
  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  // Load from and to Accounts
  let fromAccount = Account.load(from); // Check if from is address(0) since this represents mint()
  let toAccount = Account.load(to);
  fromAccount = fromAccount == null ? saveNewAccount(from) : fromAccount;
  toAccount = toAccount == null ? saveNewAccount(to) : toAccount;
  // Load Nota
  let nota = Nota.load(notaId); // Write event fires before Transfer event: nota should exist
  if (nota == null) {
    // SHOULDN'T BE THE CASE
    nota = new Nota(notaId);
    nota.save();
  }

  const transfer = new Transfer(transactionHexHash + "/" + notaId);
  transfer.caller = fromAccount.id;
  transfer.nota = notaId;
  transfer.from = fromAccount.id;
  transfer.to = toAccount.id;
  transfer.transaction = transactionHexHash;
  transfer.save();
}

// export function handleTransferred(event: TransferredEvent): void {
//   let entity = new Transferred(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.tokenId = event.params.tokenId
//   entity.from = event.params.from
//   entity.to = event.params.to
//   entity.moduleFee = event.params.moduleFee
//   entity.fundData = event.params.fundData  // ABI has this currently but transferred isn't used
//   entity.timestamp = event.params.timestamp

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

// // TODO need to add these to the Nota entity instead
// export function handleApproval(event: ApprovalEvent): void {
//   let entity = new Approval(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.owner = event.params.owner
//   entity.approved = event.params.approved
//   entity.tokenId = event.params.tokenId

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

// export function handleApprovalForAll(event: ApprovalForAllEvent): void {
//   let entity = new ApprovalForAll(
//     event.transaction.hash.concatI32(event.logIndex.toI32())
//   )
//   entity.owner = event.params.owner
//   entity.operator = event.params.operator
//   entity.approved = event.params.approved

//   entity.blockNumber = event.block.number
//   entity.blockTimestamp = event.block.timestamp
//   entity.transactionHash = event.transaction.hash

//   entity.save()
// }

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
  let module = new Module(event.params.module.toHexString());

  module.registrar = event.address.toHexString();
  module.isWhitelisted = event.params.isAccepted;
  module.save()
}

export function handleTokenWhitelisted(event: TokenWhitelistedEvent): void {
  let currency = event.params.token.toHexString();
  let ERC20Token = ERC20.load(currency);
  ERC20Token = ERC20Token == null ? saveNewERC20(currency) : ERC20Token;

  ERC20Token.isWhitelisted = event.params.accepted;
  ERC20Token.save()
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