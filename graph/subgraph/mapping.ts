import { BigInt } from "@graphprotocol/graph-ts";
import {
  Cashed as CashedEvent,
  Funded as FundedEvent,
  Written as WrittenEvent,
} from "../subgraph/generated/Events/Registrar";
import {
  Account,
  nota,
  DirectPayData,
  ERC20,
  Escrow,
  ReversiblePaymentData,
  Transaction,
} from "../subgraph/generated/schema";

import { PaymentCreated as DirectPaymentCreatedEvent } from "../subgraph/generated/DirectPay/DirectPay";

import { PaymentCreated as ReversiblePaymentCreatedEvent } from "../subgraph/generated/ReversibleRelease/ReversibleRelease";

import { PaymentCreated as DirectPaymentBridgeEvent } from "../subgraph/generated/BridgeSender/BridgeSender";
import { PaymentCreated as DirectPaymentAxelarCreatedEvent } from "../subgraph/generated/DirectPayAxelar/DirectPayAxelar";

function saveNewAccount(account: string): Account {
  const newAccount = new Account(account);
  newAccount.save();
  return newAccount;
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

export function handleWrite(event: WrittenEvent): void {
  const currency = event.params.currency.toHexString();
  const owner = event.params.owner.toHexString();
  const transactionHexHash = event.transaction.hash.toHex();
  // Load entities if they exist, else create them

  let owningAccount = Account.load(owner);
  let ERC20Token = ERC20.load(currency);
  if (ERC20Token == null) {
    ERC20Token = new ERC20(currency);
    ERC20Token.save();
  }

  owningAccount = owningAccount == null ? saveNewAccount(owner) : owningAccount;
  const notaId = event.params.notaId.toString();
  const nota = nota.load(notaId);
  const notaEscrowed = event.params.escrowed;

  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  if (nota) {
    nota.createdTransaction = transaction.id;
    nota.erc20 = ERC20Token.id;
    nota.module = event.params.module.toHexString();
    nota.escrowed = notaEscrowed;
    nota.owner = owningAccount.id;

    if (nota.moduleData && nota.moduleData.endsWith("/direct")) {
      const directPayData = DirectPayData.load(nota.moduleData);
      if (directPayData && directPayData.status != "PAID") {
        if (event.params.instant > BigInt.fromI32(0)) {
          directPayData.status = "PAID";
          directPayData.fundedTransaction = transaction.id;
          directPayData.fundedTimestamp = event.block.timestamp;
        } else {
          directPayData.status = "AWAITING_PAYMENT";
        }
        directPayData.save();
      }
    } else if (nota.moduleData && nota.moduleData.endsWith("/escrow")) {
      const reversiblePayData = ReversiblePaymentData.load(nota.moduleData);
      if (reversiblePayData) {
        if (notaEscrowed > BigInt.fromI32(0)) {
          reversiblePayData.status = "AWAITING_RELEASE";
          reversiblePayData.fundedTransaction = transaction.id;
          reversiblePayData.fundedTimestamp = event.block.timestamp;
        } else {
          reversiblePayData.status = "AWAITING_ESCROW";
        }
        reversiblePayData.save();
      }
    }
    nota.save();
  }

  const escrow = new Escrow(transactionHexHash + "/" + notaId);
  escrow.emitter = event.transaction.from.toHexString();
  escrow.transaction = transaction.id;
  escrow.timestamp = event.block.timestamp;
  escrow.nota = event.params.notaId.toString();
  escrow.from = event.transaction.from.toHexString();
  escrow.amount = notaEscrowed;
  escrow.instantAmount = event.params.instant;
  escrow.save();
}

export function handleDirectPayment(event: DirectPaymentCreatedEvent): void {
  const sender = event.transaction.from.toHexString();
  const creditor = event.params.creditor.toHexString();
  const debtor = event.params.debtor.toHexString();

  let creditorAccount = Account.load(creditor);
  let debtorAccount = Account.load(debtor);
  creditorAccount =
    creditorAccount == null ? saveNewAccount(creditor) : creditorAccount;
  debtorAccount =
    debtorAccount == null ? saveNewAccount(debtor) : debtorAccount;

  const notaId = event.params.notaId.toString();

  const directPay = new DirectPayData(notaId + "/direct");
  directPay.creditor = creditorAccount.id;
  directPay.debtor = debtorAccount.id;
  directPay.amount = event.params.amount;
  directPay.dueDate = event.params.dueDate;
  if (sender == creditor) {
    directPay.isInvoice = true;
  } else {
    directPay.isInvoice = false;
  }
  directPay.save();

  const newnota = new nota(notaId);
  const notaTimestamp = event.block.timestamp;
  newnota.timestamp = notaTimestamp;
  newnota.createdAt = notaTimestamp;
  newnota.uri = event.params.memoHash.toString();
  if (sender == creditor) {
    newnota.receiver = debtorAccount.id;
  } else {
    newnota.receiver = creditorAccount.id;
  }
  newnota.sender = sender;
  newnota.moduleData = directPay.id;
  newnota.save();
}

export function handleDirectPaymentAxelar(
  event: DirectPaymentAxelarCreatedEvent
): void {
  const sender = event.params.debtor.toHexString();
  const creditor = event.params.creditor.toHexString();
  const debtor = event.params.debtor.toHexString();

  let creditorAccount = Account.load(creditor);
  let debtorAccount = Account.load(debtor);
  creditorAccount =
    creditorAccount == null ? saveNewAccount(creditor) : creditorAccount;
  debtorAccount =
    debtorAccount == null ? saveNewAccount(debtor) : debtorAccount;

  const notaId = event.params.notaId.toString();

  const directPay = new DirectPayData(notaId + "/direct");
  directPay.creditor = creditorAccount.id;
  directPay.debtor = debtorAccount.id;
  directPay.amount = event.params.amount;
  directPay.dueDate = BigInt.fromI32(0);
  directPay.status = "PAID";
  if (sender == creditor) {
    directPay.isInvoice = true;
  } else {
    directPay.isInvoice = false;
  }
  directPay.isCrossChain = true;
  directPay.sourceChain = event.params.sourceChainId;
  directPay.destChain = event.params.destChainId;
  directPay.save();

  const newnota = new nota(notaId);
  const notaTimestamp = event.block.timestamp;
  newnota.timestamp = notaTimestamp;
  newnota.createdAt = notaTimestamp;
  newnota.uri = event.params.memoHash.toString();
  if (sender == creditor) {
    newnota.receiver = debtorAccount.id;
  } else {
    newnota.receiver = creditorAccount.id;
  }
  newnota.sender = sender;
  newnota.moduleData = directPay.id;
  newnota.save();
}

export function handleAxelarOutgoing(event: DirectPaymentBridgeEvent): void {
  const sender = event.transaction.from.toHexString();
  const creditor = event.params.creditor.toHexString();
  const debtor = event.params.debtor.toHexString();
  const transactionHexHash = event.transaction.hash.toHex();

  let creditorAccount = Account.load(creditor);
  let debtorAccount = Account.load(debtor);
  creditorAccount =
    creditorAccount == null ? saveNewAccount(creditor) : creditorAccount;
  debtorAccount =
    debtorAccount == null ? saveNewAccount(debtor) : debtorAccount;

  const notaId = event.transaction.hash.toHex();

  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  const directPay = new DirectPayData(notaId + "/direct");
  directPay.creditor = creditorAccount.id;
  directPay.debtor = debtorAccount.id;
  directPay.amount = event.params.amount;
  directPay.dueDate = BigInt.fromI32(0);
  directPay.status = "PAID";
  if (sender == creditor) {
    directPay.isInvoice = true;
  } else {
    directPay.isInvoice = false;
  }
  directPay.isCrossChain = true;
  directPay.sourceChain = event.params.chainId;
  if (event.params.destinationChain == "Polygon") {
    directPay.destChain = BigInt.fromI32(80001);
  }
  directPay.save();

  const newnota = new nota(transactionHexHash + "/crosschain");
  const notaTimestamp = event.block.timestamp;
  newnota.timestamp = notaTimestamp;
  newnota.createdAt = notaTimestamp;
  newnota.uri = event.params.memoHash.toString();
  if (sender == creditor) {
    newnota.receiver = debtorAccount.id;
  } else {
    newnota.receiver = creditorAccount.id;
  }
  newnota.owner = creditorAccount.id;
  newnota.erc20 = "0x0000000000000000000000000000000000000000"; // TODO: use right token
  newnota.sender = sender;
  newnota.moduleData = directPay.id;
  newnota.createdTransaction = transaction.id;
  newnota.save();
}

export function handleReversiblePayment(
  event: ReversiblePaymentCreatedEvent
): void {
  const sender = event.transaction.from.toHexString();
  const creditor = event.params.creditor.toHexString();
  const debtor = event.params.debtor.toHexString();
  const inspector = event.params.inspector.toHexString();

  let creditorAccount = Account.load(creditor);
  let debtorAccount = Account.load(debtor);
  let inspectorAccount = Account.load(inspector);

  creditorAccount =
    creditorAccount == null ? saveNewAccount(creditor) : creditorAccount;
  debtorAccount =
    debtorAccount == null ? saveNewAccount(debtor) : debtorAccount;
  inspectorAccount =
    inspectorAccount == null ? saveNewAccount(inspector) : inspectorAccount;

  const notaId = event.params.notaId.toString();

  const reversibleRelease = new ReversiblePaymentData(notaId + "/escrow");
  reversibleRelease.creditor = creditorAccount.id;
  reversibleRelease.debtor = debtorAccount.id;
  reversibleRelease.amount = event.params.amount;
  if (debtor == inspector) {
    reversibleRelease.isSelfSigned = true;
  } else {
    reversibleRelease.isSelfSigned = false;
  }
  if (sender == creditor) {
    reversibleRelease.isInvoice = true;
  } else {
    reversibleRelease.isInvoice = false;
  }
  reversibleRelease.save();

  const newnota = new nota(notaId);
  const notaTimestamp = event.block.timestamp;
  newnota.timestamp = notaTimestamp;
  newnota.createdAt = notaTimestamp;
  newnota.uri = event.params.memoHash.toString();
  if (sender == creditor) {
    newnota.receiver = debtorAccount.id;
  } else {
    newnota.receiver = creditorAccount.id;
  }
  newnota.sender = sender;
  newnota.moduleData = reversibleRelease.id;
  newnota.inspector = inspectorAccount.id;
  newnota.save();
}

export function handleFund(event: FundedEvent): void {
  // Load event params
  let fromAccount = Account.load(event.params.funder.toHexString());
  fromAccount =
    fromAccount == null
      ? saveNewAccount(event.params.funder.toHexString())
      : fromAccount;
  const amount = event.params.amount;
  const transactionHexHash = event.transaction.hash.toHex();
  const notaId = event.params.notaId.toString();

  // Load nota
  let nota = nota.load(notaId);
  if (nota == null) {
    // SHOULDN NEVER BE THE CASE
    nota = new nota(notaId);
    nota.save();
  }
  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  if (nota.moduleData.endsWith("/direct")) {
    const directPayData = DirectPayData.load(nota.moduleData);
    if (directPayData) {
      directPayData.status = "PAID";
      directPayData.fundedTransaction = transaction.id;
      directPayData.fundedTimestamp = event.block.timestamp;
      directPayData.save();
    }
  } else if (nota.moduleData.endsWith("/escrow")) {
    const reversiblePayData = ReversiblePaymentData.load(nota.moduleData);
    if (reversiblePayData) {
      reversiblePayData.status = "AWAITING_RELEASE";
      reversiblePayData.fundedTransaction = transaction.id;
      reversiblePayData.fundedTimestamp = event.block.timestamp;
      reversiblePayData.save();
    }
  }

  const escrow = new Escrow(transactionHexHash + "/" + notaId);
  escrow.emitter = fromAccount.id;
  escrow.transaction = transactionHexHash;
  escrow.timestamp = event.block.timestamp;
  escrow.nota = notaId;
  escrow.from = fromAccount.id;
  escrow.amount = amount;
  escrow.instantAmount = event.params.instant;
  escrow.save();
}

export function handleCash(event: CashedEvent): void {
  // Load event params
  let toAccount = Account.load(event.params.to.toHexString());
  toAccount =
    toAccount == null
      ? saveNewAccount(event.params.to.toHexString())
      : toAccount;
  const amount = event.params.amount;
  const transactionHexHash = event.transaction.hash.toHex();
  const notaId = event.params.notaId.toString();

  // Load nota
  let nota = nota.load(notaId);
  if (nota == null) {
    // SHOULDN'T BE THE CASE
    nota = new nota(notaId);
    nota.save();
  }

  // Load transaction
  const transaction = saveTransaction(
    transactionHexHash,
    event.block.timestamp,
    event.block.number
  );

  if (nota.moduleData.endsWith("/escrow")) {
    const reversiblePayData = ReversiblePaymentData.load(nota.moduleData);
    if (reversiblePayData) {
      if (nota.owner == toAccount.id) {
        reversiblePayData.status = "RELEASED";
      } else {
        reversiblePayData.status = "VOIDED";
      }
      reversiblePayData.save();
    }
  }

  const escrow = new Escrow(transactionHexHash + "/" + notaId);
  escrow.emitter = toAccount.id;
  escrow.transaction = transactionHexHash;
  escrow.timestamp = event.block.timestamp;
  escrow.nota = notaId;
  escrow.from = toAccount.id;
  escrow.amount = amount.neg();
  escrow.save();
}

// TODO: Transfer event being fired before write event is causing problems
// export function handleTransfer(event: TransferEvent): void {
//   // Load event params
//   const from = event.params.from.toHexString();
//   const to = event.params.to.toHexString();
//   const notaId = event.params.tokenId.toHexString();
//   const transactionHexHash = event.transaction.hash.toHex();
//   // Load from and to Accounts
//   let fromAccount = Account.load(from); // Check if from is address(0) since this represents mint()
//   let toAccount = Account.load(to);
//   fromAccount = fromAccount == null ? saveNewAccount(from) : fromAccount;
//   toAccount = toAccount == null ? saveNewAccount(to) : toAccount;
//   // Load nota
//   let nota = nota.load(notaId); // Write event fires before Transfer event: nota should exist
//   if (nota == null) {
//     // SHOULDN'T BE THE CASE
//     nota = new nota(notaId);
//     nota.save();
//   }
//   // Update accounts' nota balances
//   if (event.params.from != Address.zero()) {
//     fromAccount.numnotasOwned = fromAccount.numnotasSent.minus(
//       BigInt.fromI32(1)
//     );
//     fromAccount.save();
//   }
//   toAccount.numnotasOwned = toAccount.numnotasOwned.plus(BigInt.fromI32(1));
//   toAccount.save();
//   const transaction = saveTransaction(
//     transactionHexHash,
//     notaId,
//     event.block.timestamp,
//     event.block.number
//   );
//   const transfer = new Transfer(transactionHexHash + "/" + notaId);
//   transfer.emitter = fromAccount.id;
//   transfer.transaction = transactionHexHash;
//   transfer.timestamp = event.block.timestamp;
//   transfer.nota = notaId;
//   transfer.from = fromAccount.id;
//   transfer.to = toAccount.id;
//   transfer.save();
// }

// export function handleWhitelist(event: ModuleWhitelisted): void {
//   const module = event.params.module;
//   const isAccepted = event.params.isAccepted;
//   // const moduleName = event.params.moduleName;
// }
