# Denota-SDK Documentation:

## Introduction:

@denota-labs/denota-sdk is a JavaScript library that allows you to send "notas," NFTs that represent escrowed tokens. The library is built using EVM blockchain technology and requires a web3 connection to function. It provides an interface to write (send), transfer, fund, cash, and approve notas. Denota is currently available on Polygon Mainnet as a beta.

## Installation:

You can install the @denota-labs/denota-sdk using the npm package manager with the following command:

```bash
npm install @denota-labs/denota-sdk
```

## Setup:

Before you can use the @denota-labs/denota-sdk, you need to set up a web3 connection. You can do this by calling the setProvider function and passing in your web3 connection. This function initializes the Ethereum provider, signer, and the contracts required to write notas.

```javascript
import { setProvider } from '@denota-labs/denota-sdk';

async function init() {
  const web3Connection = // your web3 connection here
  await setProvider(web3Connection);
}

init();
```

After setting up the web3 connection, you can use the @denota-labs/denota-sdk to write notas. 

Before sending funds, use the approveToken function to approve a token for use in writing notas.

```javascript
import { approveToken } from '@denota-labs/denota-sdk';

async function approve() {
  const currency = 'DAI';
  const approvalAmount = 100;
  await approveToken({ currency, approvalAmount });
}

approve();
```

## Direct Pay:

```javascript
import Denota from '@denota-labs/denota-sdk';

async function createNota() {
  const { txHash, notaId } = await Denota.write({
    amount: 1,
    currency: "DAI",
    module: {
      moduleName: "direct",
      type: "invoice",
      creditor: "0x...",
      debitor: "0x...",
      notes: "Example invoice",
    },
  });
}

createNota();
```

In the above code, we pass in the module object, which contains the details of the nota. We also pass in the amount and currency parameters, which represent the amount and the currency in which the nota is written.

To create an invoice, set the type property of the module object to "invoice". To send a payment, set it to "payment". Provide the Ethereum addresses of the debitor (payer) and creditor (payee). 

You can also provide optional notes or a file for the nota. If you have an IPFS hash, you can provide it using the ipfsHash property.

## Reversible Release (Escrow):

To create an escrow, set the moduleName property of the module object to "reversibleRelease" and provide the inspector property. The inspector is the party in charge of releasing or reversing the payment. If no inspector is provided, the payer is set as the inspector.  

ReversibleRelease supports the same metadata options as DirectPay.

```javascript
async function createNota() {
  const { txHash, notaId } = await Denota.write({
    amount: 1,
    currency: "DAI",
    module: {
      moduleName: "reversibleRelease",
      type: "invoice",
      inspector: "0x...",
      creditor: "0x...",
      debitor: "0x...",
      notes: "Example invoice",
    },
  });
}

createNota();
```

To release or reverse a payment, the inspector uses the cash function


```javascript
async function releaseNota() {
  const receipt = await Denota.cash({ notaId: "0", type: "release" });
}

async function reverseNota() {
  const receipt = await Denota.cash({ notaId: "0", type: "reverse" });
}
```