## Set up
Run the command below to install from scratch:
```
make fresh-install
```

Run the local blockchain for deployment/testing:
```
anvil
```

Build the contracts:
```
forge build
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

Run the commands below to update dependencies:
```
forge update lib/forge-std
forge update lib/openzeppelin-contracts
```
## Foundry/Forge Tips
Check out the [Foundry Book](https://book.getfoundry.sh/) for more specifics.

### Updating Dependencies
```forge update``` will update all dependencies at once.

### Testing
```forge test``` will run all tests.
```forge test -m nameOfTest``` will run a specific test.

## Linting/Formatting
(TODO: this currently doesn't work)
Run ```npm run solhint``` for linting to see Solidity warnings and errors.
Use ```npm run prettier:ts``` and ```npm run prettier:solidity``` to manually format TypeScript and Solidity.
These commands are automatically run pre-push via [Husky](https://github.com/typicode/husky) Git hooks.