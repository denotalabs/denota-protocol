# Denota's Architecture
An overview of what happens between a user initiating a transaction and a Nota being minted.

## The Nota Registrar
The Registrar is where Notas are minted, their funds are held, and where Payment Agreements are whitelisted. The interface is acronymed as WTFCAT (very memorable), where `write` and `transfer` directly affect ownership, and `fund` and `cash` affect escrow. `approve`, `tokenURI`, and `burn` are also inherited from the ERC721 standard.

## Payment Agreements
Each Nota contains a reference to a Payment Agreement which is an external contract responsible for the logic that each Nota follows as well as any additional information Notas contain. Whenever a WTFCATB function is called, a Payment Agreement hook is also called so the hook can either revert or update it's storage accordingly. Every WTFCAT function (save for approve, and tokenURI) has a bytes parameter that hooks can use to decode variables specific to their logic. This is how the Registrar is able to be called regardless of hook while each Pay Agreement can recieve it's hook specific arguments.

## Onchain tokenURIs
The Denota protocol aims to give individuals as much sovereignty and transparancy as possible. For that reason, tokenURIs are represented as on-chain JSONs so that users can be sure that what they are receiving is what the sender claims it to be. Marketplaces following the Metadata standard will correctly display how much of what currency is escrowed, which payment agreement is referenced, as well as the Nota's hook specific attributes.

- Separate the protocol from the SDK+Graph
- Rename to v1-core? Move to separate organization?

- Fix the graph files (use what’s inside the `denota` path)
- Separate SDK and the Graph?

- Use Foundry script to do NotaRegistrar deployment
- Move ERC721 approve() code to the NotaRegistrar. Same for transfer
- Transfer and Transferred events need to be in respective order?
- Put totalSupply() back..?