## Our Mission
TradFi payments expect a number of protections crypto doesn't provide (disputation, reversibility, etc), legal and regulatory checks, attachment of metadata, and more. Payments also represent trust, reputation, and identity. Denota can provide all of these things, and more, to the crypto world. We will help individuals feel safe transaction in cryptocurrency, give them more optionality, and help them build their reputation and identity in the crypto world. We believe in the mission of cryptocurrency, bringing financial inclusion, permissionlessness, trust minimization, and global cooperation. Crypto doesn't have to be synonymous with risk, illegality, or technical jargon. Denota is building payment primitives for the crypto world and the mainstream.

# Denota's Architecture
An overview of what happens between a user initiating a transaction and a Nota being minted.

## The Nota Factory
This is where Nota contracts are deployed, their information is stored, and where they are minted. The Nota Factory is a singleton contract that is deployed once and never again. It is responsible for deploying Nota contracts, storing their information, and minting them. The Nota Factory is also responsible for storing the address of the Registrar contract.

## Nota Agreements


## On-Chain tokenURIs
The Denota protocol aims to give individuals as much sovereignty and transparancy as possible. For that reason, tokenURIs are represented as on-chain JSONs so that users can be sure that what they are receiving is what the sender claims it to be. Marketplaces following the Metadata standard will correctly display how much of what currency is escrowed, which payment agreement is referenced, as well as the Nota's specific attributes.
