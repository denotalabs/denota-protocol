-include .env

all: clean remove install update solc build 

# Install Foundry, node packages, and foundry libraries
fresh-install:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	foundryup
	# make install  # forge build installs these

# Compiles the contracts
build  :; forge clean && forge build --optimize --optimizer-runs 1000000

deploy-local:
	forge script src/script/01_deployRegistrar.s.sol:DeployRegistrar --fork-url http://localhost:8545 --private-key ${PRIVATE_KEY_LOCAL} -vvvv --via-ir

deploy-mumbai:
	forge script src/script/01_deployRegistrar.s.sol:DeployRegistrar --rpc-url ${MUMBAI_RPC_URL} --private-key ${PRIVATE_KEY} --via-ir

deploy-arbitrum-goerli:
	forge script src/script/01_deployRegistrar.s.sol:DeployRegistrar --rpc-url ${ARBITRUM_GOERLI_RPC_URL} --private-key ${PRIVATE_KEY} --via-ir

# create-mumbai-data: # write notas from different modules, transfer, fund, cash
# 	python3 createNotas.py ${PRIVATE_KEY} "mumbai"



# Install proper solc version.
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

# Install the Modules
install :; 
	forge install foundry-rs/forge-std
	forge install dapphub/ds-test --no-commit
	forge install OpenZeppelin/openzeppelin-contracts --no-commit
	forge install axelarnetwork/axelar-gmp-sdk-solidity --no-commit