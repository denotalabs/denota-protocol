## Quickstart
Install Foundry for compiling, deploying, and testing:
```
make fresh-install
```

Build the contracts:
```
forge build
```
Test the contracts:
```
forge test
```
Run the local blockchain for deployment:
```
anvil
```
Deploy the contracts to the blockchain (local)
```
make deploy-local
```

Deploy the contracts to the blockchain (mumbai)
```
export PRIVATE_KEY=YOUR_KEY
make deploy-mumbai
```

Update dependencies:
```
forge update lib/forge-std
forge update lib/openzeppelin-contracts
forge update dapphub/ds-test --no-commit
forge update OpenZeppelin/openzeppelin-contracts --no-commit
forge update axelarnetwork/axelar-gmp-sdk-solidity --no-commit
```
## Foundry
Check out the [Foundry Book](https://book.getfoundry.sh/) for more specifics.

### Updating Dependencies
```forge update``` will update all dependencies at once.


## Linting/Formatting
(TODO: this currently doesn't work)
Run ```npm run solhint``` for linting to see Solidity warnings and errors.
Use ```npm run prettier:ts``` and ```npm run prettier:solidity``` to manually format TypeScript and Solidity.
These commands are automatically run pre-push via [Husky](https://github.com/typicode/husky) Git hooks.