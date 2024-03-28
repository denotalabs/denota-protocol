import { BigInt } from "@graphprotocol/graph-ts";
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
import { handleHookData } from "./hooks";

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

 // TODO TODO what about WTFC on behalf of? Use logged calldata or the tx.from?
export function handleWritten(event: WrittenEvent): void {
  const currency = event.params.currency.toHexString();
  const owner = event.params.owner.toHexString();
  const sender = event.transaction.from.toHexString();
  const module = event.params.module.toHexString();
  const transactionHexHash = event.transaction.hash.toHexString();  // TODO is necessary to convert to hex string?
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
  nota.token = ERC20Token.id;
  nota.escrowed = event.params.escrowed;
  nota.module = moduleEntity.id;
  nota.sender = senderAccount.id;
  nota.receiver = owningAccount.id;
  nota.owner = owningAccount.id;
  nota.save();

  const entity = new Written(transactionHexHash + "/" + nota.id); // TODO + "/" + event.logIndex.toI32() should be added in case of single tx using same nota
  entity.caller = senderAccount.id;
  entity.nota = nota.id;
  entity.owner = owningAccount.id;
  entity.instant = event.params.instant;
  entity.token = ERC20Token.id;
  entity.escrowed = event.params.escrowed;
  entity.moduleFee = event.params.moduleFee;
  entity.module = moduleEntity.id;
  entity.writeBytes = event.params.moduleData;
  entity.transaction = transaction.id;
  entity.save();

  handleHookData(nota.id, moduleEntity.id, event.params.moduleData);  // Parses the bytes and saves the args to the appropriate hookData entity
}

export function handleFunded(event: FundedEvent): void {
  const transactionHexHash = event.transaction.hash.toHexString();
  let fromAccount = Account.load(event.transaction.from.toHexString());
  fromAccount =
    fromAccount == null
      ? saveNewAccount(event.transaction.from.toHexString())
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
  let callerAccount = Account.load(event.params.funder.toHexString());
    callerAccount =
      callerAccount == null
        ? saveNewAccount(event.params.funder.toHexString())
        : callerAccount;

  let entity = new Funded(transactionHexHash + "/" + notaId);
  entity.caller = callerAccount.id;
  entity.nota = nota.id;
  entity.amount = event.params.amount;
  entity.instant = event.params.instant;
  entity.fundBytes = event.params.fundData;
  entity.moduleFee = event.params.moduleFee;
  entity.transaction = transaction.id;
  entity.save();

  nota.escrowed = nota.escrowed.plus(event.params.amount);
  nota.save();
}

export function handleCashed(event: CashedEvent): void {
    let toAccount = Account.load(event.params.to.toHexString());
    toAccount =
      toAccount == null
        ? saveNewAccount(event.params.to.toHexString())
        : toAccount;
    
    const transactionHexHash = event.transaction.hash.toHexString();
    const transaction = saveTransaction(
      transactionHexHash,
      event.block.timestamp,
      event.block.number
    );
    const notaId = event.params.notaId.toString();
  
    // Load nota
    let nota = Nota.load(notaId);
    if (nota == null) {
      nota = new Nota(notaId);
      nota.save();
    }
  
    nota.escrowed = nota.escrowed.minus(event.params.amount);
    nota.save();

    let callerAccount = Account.load(event.transaction.from.toHexString());
    callerAccount =
      callerAccount == null
        ? saveNewAccount(event.transaction.from.toHexString())
        : callerAccount;

    let entity = new Cashed(transactionHexHash + "/" + notaId)
    entity.caller = callerAccount.id;
    entity.nota = nota.id;
    entity.to = event.params.to;
    entity.amount = event.params.amount;
    entity.cashBytes = event.params.cashData;
    entity.moduleFee = event.params.moduleFee;
    entity.transaction = transaction.id;
  
    entity.save();
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

export function handleApproval(event: ApprovalEvent): void {
  const transactionHexHash = event.transaction.hash.toHexString();
  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  // Load nota
  const notaId = event.params.tokenId.toString();
  let nota = Nota.load(notaId);
  if (nota == null) {
    nota = new Nota(notaId);
    nota.save();
  }
  
  let entity = new Approval(transactionHexHash + "/" + notaId);
  entity.caller = event.transaction.from.toHexString();
  entity.owner = event.params.owner.toHexString();
  entity.approved = event.params.approved.toHexString();
  entity.nota = nota.id;
  entity.transaction = transaction.id;
  entity.save();
}

export function handleApprovalForAll(event: ApprovalForAllEvent): void {
  const transactionHexHash = event.transaction.hash.toHexString();
  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  let entity = new ApprovalForAll(transactionHexHash + "/" + event.params.owner.toHexString() + "/" + event.params.operator.toHexString()
  );
  entity.caller = event.transaction.from.toHexString();
  entity.owner = event.params.owner.toHexString();
  entity.operator = event.params.operator.toHexString();
  entity.approved = event.params.approved;
  entity.transaction = transaction.id;
  entity.save()
}

// TODO: Transfer event being fired before write event is causing problems
export function handleTransfer(event: TransferEvent): void {
  // Load event params
  const caller = event.transaction.from.toHexString();
  const from = event.params.from.toHexString();
  const to = event.params.to.toHexString();
  const notaId = event.params.tokenId.toHexString();
  const transactionHexHash = event.transaction.hash.toHexString();
  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  // Load from and to Accounts
  let fromAccount = Account.load(from); // Check if from is address(0) since this represents mint()
  let toAccount = Account.load(to);
  let callerAccount = Account.load(caller);
  fromAccount = fromAccount == null ? saveNewAccount(from) : fromAccount;
  toAccount = toAccount == null ? saveNewAccount(to) : toAccount;
  callerAccount = callerAccount == null ? saveNewAccount(caller) : callerAccount;
  
  let nota = Nota.load(notaId); // Transfer event fires before Written event
  if (nota == null) {
    nota = new Nota(notaId);
    nota.escrowed = new BigInt(0);
    nota.save();
  }

  const transfer = new Transfer(transactionHexHash + "/" + notaId);
  transfer.caller = fromAccount.id;
  transfer.nota = notaId;
  transfer.from = fromAccount.id;
  transfer.to = toAccount.id;
  transfer.transaction = transaction.id;
  transfer.save();
}

export function handleBatchMetadataUpdate(
  event: BatchMetadataUpdateEvent
): void {
  let entity = new BatchMetadataUpdate(
    event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
  )
  entity._fromTokenId = event.params._fromTokenId
  entity._toTokenId = event.params._toTokenId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleMetadataUpdate(event: MetadataUpdateEvent): void {
  const transactionHexHash = event.transaction.hash.toHexString(); 
  let caller = Account.load(event.transaction.from.toHexString());
  caller =
    caller == null
      ? saveNewAccount(event.transaction.from.toHexString())
      : caller;
    
  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  const notaId = event.params._tokenId.toString();
  let nota = Nota.load(notaId);
  if (nota == null) {
    // SHOULDN NEVER BE THE CASE
    nota = new Nota(notaId);
    nota.save();
  }

  let entity = new MetadataUpdate(
    event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
  )
  
  entity.caller = caller.id;
  entity.nota = nota.id;
  entity.transaction = transaction.id;
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
    event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
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
    event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}