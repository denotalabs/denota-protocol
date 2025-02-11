# Denota Protocol V1
Denota is a token agreement protocol designed for the EVM. It enables users to mint and interact with token agreement NFTs (Notas for short) which can store a token balance, arbitrary metadata, and the address of it's hook logic. Hooks act as both a validation and additional storage layer for Notas and can be deployed permisionlessly. Any action that modifies the Nota's state (token balance, ownership, or metadata) calls into the hook which determines what fee to charge and what action (if any) to call next. By treating agreements as first-class assets, Denota provides a foundation for developers to build modular financial, contractual, and governance mechanisms onchain.

## Quickstart
Run the command below to install from scratch:
```
make fresh-install
```

Build the contracts:
```
forge build
```
## Testing
```
forge test
```
Adding ```-m nameOfTestContract``` will run a specific test.
## Deployments
### Local
Run a local blockchain:
```
anvil
```
Deploy the contracts to the local blockchain
```
make deploy-local
```
### Testnets
Deploy to all supported testnets (if not already deployed)
```
export PRIVATE_KEY=YOUR_KEY
make deploy-testnets
```
If you wish to redeploy to a specific testnet, delete the desired contract address in contractAddresses.json.

## Foundry Extras
Foundry compiles, deploys, tests, and manages dependencies for your contracts. It also lets you interact with the chain from the command-line and via Solidity scripts.
Check out the [Foundry Book](https://book.getfoundry.sh/) for more specifics.

### Updating Dependencies
```forge update``` will update all dependencies at once.

## Linting/Formatting
(TODO: this currently doesn't work)
Run ```npm run solhint``` for linting to see Solidity warnings and errors.
Use ```npm run prettier:ts``` and ```npm run prettier:solidity``` to manually format TypeScript and Solidity.
These commands are automatically run pre-push via [Husky](https://github.com/typicode/husky) Git hooks.
