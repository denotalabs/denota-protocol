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

