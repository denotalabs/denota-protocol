# Denota-SDK Documentation:

## Introduction:

@denota-labs/denota-sdk is a JavaScript library that allows you to write "notas," NFTs that represent invoices or escrows. The library is built using EVM blockchain technology and requires a web3 connection to function. It provides an interface to create, approve, and write invoices and escrows. In this documentation, we will explain how to use the @denota-labs/denota-sdk to write notas. Denota is currently available on Polygon Mumbai Testnet and Celo Alfajores Testnet.

## Installation:

You can install the @denota-labs/denota-sdk using the npm package manager with the following command:

```bash
npm install @denota-labs/denota-sdk
```

## Usage:

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

```javascript
import Denota from '@denota-labs/denota-sdk';

async function createNota() {
  const receipt = await Denota.write({
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

  console.log(receipt);
}

createNota();
```

In the above code, we pass in the module object, which contains the details of the nota. We also pass in the amount and currency parameters, which represent the amount and the currency in which the nota is written.

To create an invoice, set the type property of the module object to "invoice" and provide the Ethereum addresses of the creditor and debitor. You can also provide optional notes or a file for the invoice. If you have an IPFS hash for the invoice, you can provide it using the ipfsHash property.

To create an escrow, set the moduleName property of the module object to "reversibleRelease" and provide the inspector property.

You can also use the approveToken function to approve a token for use in writing notas.

```javascript
import { approveToken } from '@denota-labs/denota-sdk';

async function approve() {
  const currency = 'DAI';
  const approvalAmount = 100;
  await approveToken({ currency, approvalAmount });
}

approve();
```

In the above code, we pass in the currency and approvalAmount parameters to approve the specified token for use in writing notas.
