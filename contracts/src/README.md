# Denota's Architecture
An overview of what happens between a user initiating a transaction and a Nota being minted.

## The Nota Registrar
The Registrar is where Notas are minted, their funds are held, and where Payment Agreements are whitelisted. The interface is acronymed as WTFCAT (very memorable), where `write` and `transfer` directly affect ownership, and `fund` and `cash` affect escrow. `approve` and `tokenURI` are also inherited from the ERC721 standard.

## Payment Agreements
Each Nota contains a reference to a Payment Agreement module which is an external contract responsible for the logic that each Nota follows as well as any additional information Notas contain. Whenever a WTFCAT function is called, a Payment Agreement hook is also called so the module can either revert or update it's storage accordingly. Every WTFCAT function (save for tokenURI) has a bytes parameter that modules can use to decode variables specific to their logic. This is how the Registrar is able to be called regardless of module while each Pay Agreement can recieve it's module specific arguments.

## On-Chain tokenURIs
The Denota protocol aims to give individuals as much sovereignty and transparancy as possible. For that reason, tokenURIs are represented as on-chain JSONs so that users can be sure that what they are receiving is what the sender claims it to be. Marketplaces following the MetaData standard will correctly display how much of what currency is escrowed, which payment agreement is referenced, as well as the Nota's module specific attributes.