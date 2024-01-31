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
  Written, Transaction, ERC20, Account, Escrow, Nota, Module
} from "../generated/schema"
// , NotaRegistrar, . Update these entities too
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
  const transactionHexHash = event.transaction.hash.toHex();

  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  let owningAccount = Account.load(owner);
  owningAccount = owningAccount == null ? saveNewAccount(owner) : owningAccount;
  let ERC20Token = ERC20.load(currency);
  ERC20Token = ERC20Token == null ? saveNewERC20(currency) : ERC20Token;

  const notaId = event.params.notaId.toString();
  const nota = new Nota(notaId);  // nota.save();

  nota.erc20 = ERC20Token.id;
  nota.module = event.params.module.toHexString();
  nota.escrowed = event.params.escrowed;
  nota.sender = "";
  nota.receiver = "";
  nota.owner = owningAccount.id;
  // nota.uri = "";
  nota.createdTransaction = transaction.id;
  // nota.moduleData = "";

  // Attaching hook specific parameters
  // TODO
  nota.save();

  const escrow = new Escrow(transactionHexHash + "/" + notaId);
  escrow.nota = event.params.notaId.toString();
  escrow.caller = event.transaction.from.toHexString();
  escrow.to = event.address.toHexString();
  escrow.amount = event.params.escrowed;
  escrow.instant = event.params.instant;
  escrow.moduleFee = event.params.moduleFee
  escrow.transaction = transaction.id;
  escrow.save();
}

export function handleFunded(event: FundedEvent): void {
    // Load event params
    let fromAccount = Account.load(event.params.funder.toHexString());
    fromAccount =
      fromAccount == null
        ? saveNewAccount(event.params.funder.toHexString())
        : fromAccount;
    const amount = event.params.amount;
    const transactionHexHash = event.transaction.hash.toHex();
    const notaId = event.params.notaId.toString();
    const transaction = saveTransaction(
      transactionHexHash,
      event.block.timestamp,
      event.block.number
    );
  
    // Load nota
    let nota = Nota.load(notaId);
    if (nota == null) {
      // SHOULDN NEVER BE THE CASE
      nota = new Nota(notaId);
      nota.save();
    }
    

    // Attaching hook specific parameters
    // TODO

    const escrow = new Escrow(transactionHexHash + "/" + notaId);
    escrow.nota = notaId;
    escrow.caller = fromAccount.id;
    escrow.to = event.address.toHexString();
    escrow.amount = amount;
    escrow.instant = event.params.instant;
    escrow.moduleFee = event.params.moduleFee
    escrow.transaction = transaction.id;
    escrow.save();

    // nota.escrowed += amount;  // TODO does this need to be done or front end handles?
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
  
    const escrow = new Escrow(transactionHexHash + "/" + notaId);
    escrow.caller = event.params.casher.toHexString();
    escrow.to = toAccount.id;
    escrow.amount = amount.neg();
    // escrow.instant = instant;
    escrow.nota = notaId;
    // escrow.cashData = event.params.cashData
    escrow.moduleFee = event.params.moduleFee
    escrow.transaction = transaction.id;
    escrow.save();  
    // nota.escrowed -= amount;  // TODO does this need to be done or front end handles?
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

export function handleTransferred(event: TransferredEvent): void {
  let entity = new Transferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.tokenId = event.params.tokenId
  entity.from = event.params.from
  entity.to = event.params.to
  entity.moduleFee = event.params.moduleFee
  entity.fundData = event.params.fundData  // ABI has this currently but transferred isn't used
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

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
  let erc20 = new ERC20(event.params.token.toHexString());

  erc20.isWhitelisted = event.params.accepted;
  erc20.save()
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