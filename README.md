# Denota JS SDK Documentation
The Denota JS SDK provides a simple interface for sending and querying "notas", which are NFTs that represent invoices, payments, or escrows with attached metadata. The SDK currently supports **Polygon Testnet Mumbai** and **Celo Testnet Alfajores**

## Installation
To use the Denota JS SDK in your project, install it using NPM:

```bash
npm install denota-sdk
```

## Setup
Before using the Denota JS SDK, you must set the provider using the setProvider function. This function takes a provider object that conforms to the Web3 provider API.

```typescript
import { setProvider } from 'denota-js-sdk';
setProvider(web3.currentProvider);
```

## Direct Payments
You can send a direct payment or direct payment invoice using the sendDirectPayment and sendDirectPayInvoice functions, respectively. Both functions take a DirectPayProps object as an argument. The DirectPayProps object has the following properties:

**recipient**: the Ethereum address of the recipient

**token**: the Ethereum token address or symbol to use for payment

**amount**: the amount of the token to send

**note**: a string note to attach to the NFT

**file**: a file object to attach to the NFT

```typescript
import { sendDirectPayment, sendDirectPayInvoice } from 'denota-js-sdk';

const directPayProps = {
  recipient: '0x1234567890abcdef1234567890abcdef1234567',
  token: 'ETH',
  amount: 1,
  note: 'This is a note.',
  file: myFile
};

// Send a direct payment
sendDirectPayment(directPayProps);

// Send a direct payment invoice
sendDirectPayInvoice(directPayProps);
```

### Fund Direct Payment Invoice
You can fund a direct payment invoice using the fundDirectPayInvoice function. This function takes a FundDirectPayProps object as an argument. The FundDirectPayProps object has the following properties:

**cheqId**: the ID of the direct payment invoice to fund

```typescript
import { fundDirectPayInvoice } from 'denota-js-sdk';

const fundDirectPayProps = {
  cheqId: 1
};

fundDirectPayInvoice(fundDirectPayProps);
```

## Reversible Payments
You can send a reversible payment or reversible payment invoice using the sendReversiblePayment and sendReversibleInvoice functions, respectively. Both functions take a ReversiblePaymentProps object as an argument. The ReversiblePaymentProps object has the following properties:

**recipient**: the Ethereum address of the recipient

**token**: the Ethereum token address or symbol to use for payment

**amount**: the amount of the token to send

**note**: a string note to attach to the NFT

**file**: a file object to attach to the NFT

**inspectionPeriod**: the number of seconds for the inspection period (default: 60 days)

```typescript
import { sendReversiblePayment, sendReversibleInvoice } from 'denota-js-sdk';

const reversiblePaymentProps = {
  recipient: '0x1234567890abcdef1234567890abcdef1234567',
  token: 'ETH',
  amount: 1,
  note: 'This is a note.',
  file: myFile,
  inspectionPeriod: 120
};

// Send a reversible payment
sendReversiblePayment(reversiblePayment)
```

### Reverse Payment
You can reverse a reversible payment using the reversePayment function. This function takes a ReversePaymentProps object as an argument. The ReversePaymentProps object has the following properties:

**cheqId**: the ID of the reversible payment to reverse

```typescript
import { reversePayment } from 'denota-js-sdk';

const reversePaymentProps = {
  cheqId: 123
};

reversePayment(reversePaymentProps);
```

## Milestones
The Milestone interface represents a milestone that can be associated with a payment. It has the following properties:

amount: a number representing the amount of tokens associated with the milestone.
note: a string representing a note associated with the milestone.
targetCompletion: a Date representing the date the milestone is expected to be completed.

### sendMilestoneInvoice
The sendMilestoneInvoice function creates a new milestone invoice for the recipient. The function takes a MilestoneProps object as its argument, which has the following properties:

milestones: an array of Milestone objects representing the milestones associated with the payment.
token: a string representing the Ethereum token used for payment.
recipient: a string representing the Ethereum address of the recipient.
file: a File object representing a file attachment to the NFT.

```typescript
import { sendMilestoneInvoice, MilestoneProps } from 'denota-js-sdk';

const milestones = [
  { amount: 100, note: 'Milestone 1', targetCompletion: new Date('2023-03-03') },
  { amount: 200, note: 'Milestone 2', targetCompletion: new Date('2023-04-03') },
];

const milestoneProps: MilestoneProps = {
  milestones,
  token: '0x...',
  recipient: '0x...',
  file: new File([], 'filename'),
};

sendMilestoneInvoice(milestoneProps).then((nota) => {
  console.log(nota);
});
```

### sendMilestonePayment
The sendMilestonePayment function sends a payment for a previously created milestone invoice. The function takes a MilestonePaymentProps object as its argument, which has the following properties:

milestones: an array of Milestone objects representing the milestones associated with the payment.
token: a string representing the Ethereum token used for payment.
recipient: a string representing the Ethereum address of the recipient.
file: a File object representing a file attachment to the NFT.
fundedMilestones: an array of milestone indexes (starting at 0) that have been funded.

```typescript
import { sendMilestonePayment, MilestonePaymentProps } from 'denota-js-sdk';

const milestones = [
  { amount: 100, note: 'Milestone 1', targetCompletion: new Date('2023-03-03') },
  { amount: 200, note: 'Milestone 2', targetCompletion: new Date('2023-04-03') },
];

const milestonePaymentProps: MilestonePaymentProps = {
  milestones,
  token: '0x...',
  recipient: '0x...',
  file: new File([], 'filename'),
  fundedMilestones: [0],
};

sendMilestonePayment(milestonePaymentProps).then((nota) => {
  console.log(nota);
});
```

## Batch Payments 

The sendBatchPayment function allows you to send a batch of payments in a single transaction. The function takes a single argument, an object of type BatchPayment, which contains an optional file and an array of payment items. Each payment item has an amount, token, recipient, and an optional note.

Example usage:

```javascript
sendBatchPayment({
  file: myFile,
  items: [
    {
      amount: 100,
      token: "ETH",
      recipient: "0x1234...",
      note: "Payment for services rendered"
    },
    {
      amount: 50,
      token: "DAI",
      recipient: "0x5678...",
      note: "Payment for products purchased"
    },
    // add more payment items as needed
  ]
});
```

### sendBatchPaymentFromCSV

The sendBatchPaymentFromCSV function allows you to send a batch of payments from a CSV file. The CSV file must have a header row with the following column names: amount, token, recipient, and note. Each row after the header row represents a payment item.

Example usage:

```javascript
sendBatchPaymentFromCSV(myCSVFile);
```

Note: The CSV file should be of the format:

```
amount,token,recipient,note
100,ETH,0x1234...,Payment for services rendered
50,DAI,0x5678...,Payment for products purchased
```

## Query Notas 
[GraphQL schema](schema.graphql)

[GraphiQL playground](TODO)

You can fetch notas using the fetchNotas function. This function takes a GraphQL query string as an argument and returns a Promise that resolves to an array of Nota objects. The Nota object has the following properties:

**id**: the ID of the nota

**type**: the type of the nota (invoice, payment, or escrow)

**status**: the status of the nota (pending, paid, or canceled)

**sender**: the Ethereum address of the sender

**recipient**: the Ethereum address of the recipient

**token**: the Ethereum token address or symbol used for payment

**amount**: the amount of the token paid

**note**: a string note attached to the NFT

**file**: a file object attached to the NFT

**createdAt**: the timestamp when the nota was created

**updatedAt**: the timestamp when the nota was last updated

Here is an example query you can use with the fetchNotas function:

```typescript
import { fetchNotas } from 'denota-js-sdk';

const query = `query {
  account(where: { id: $account }) {
    chegs {
      id
      amount
      timestamp
      status
      erc20 {
        id
        payer {
          id
        }
        recipient {
          id
        }
        metadata {
          id
          note
          files {
            id
            uri
          }
        }
      }
    }
  }
}`;

fetchNotas(query).then((notas) => {
  console.log(notas);
});
```