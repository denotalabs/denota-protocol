-include .env

all: clean remove install update solc build 

# Install proper solc version.
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

# Clean the repo
clean  :; forge clean

# Install the Modules
install :; 
	forge install foundry-rs/forge-std
	forge install dapphub/ds-test --no-commit
	forge install OpenZeppelin/openzeppelin-contracts --no-commit
	forge install axelarnetwork/axelar-gmp-sdk-solidity --no-commit

# Update Dependencies
update:; forge update

build-forge:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	~/.foundry/bin/foundryup
	~/.foundry/bin/forge build

# Install Foundry, node packages, and foundry libraries
fresh-install:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	foundryup
	# make install  # forge build installs these

# Builds
build  :; forge clean && forge build --optimize --optimizer-runs 1000000

deploy-local:
	# source .env
	python3 deployCheq.py ${PRIVATE_KEY} "local"
	
deploy-mumbai:
	# source .env
	python3 deployCheq.py ${PRIVATE_KEY} "mumbai"

create-mumbai-data: # write cheqs from different modules, transfer, fund, cash
	# source .env
	python3 createCheq.py ${PRIVATE_KEY} "mumbai"