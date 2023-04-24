# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

all: clean remove install update solc build 

# Install proper solc version.
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install the Modules
install :; 
	cd contracts && forge install foundry-rs/forge-std
	cd contracts && forge install dapphub/ds-test --no-commit
	cd contracts && forge install OpenZeppelin/openzeppelin-contracts --no-commit
	cd contracts && forge install axelarnetwork/axelar-gmp-sdk-solidity --no-commit

# Update Dependencies
update:; forge update

setup-yarn:
	yarn 

# TODO: fails on fleek due to "GLIBC_2.29 not found"
build-forge:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	~/.foundry/bin/foundryup
	~/.foundry/bin/forge build

# Install Foundry, node packages, and foundry libraries
fresh-install:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	foundryup
	npm install
	# make install  # forge build installs these

# Builds
build  :; forge clean && forge build --optimize --optimizer-runs 1000000

run: 
	(npm run dev | sed -e 's/^/[NPM] : /' & anvil | sed -e 's/^/[ANVIL] : /')

deploy-local:
	# source .env
	python3 deployCheq.py ${PRIVATE_KEY} "local"
	
deploy-mumbai:
	# source .env
	python3 deployCheq.py ${PRIVATE_KEY} "mumbai"

create-mumbai-data: # write cheqs from different modules, transfer, fund, cash
	# source .env
	python3 createCheq.py ${PRIVATE_KEY} "mumbai"

graph-start:
	# Requires docker to be running
	cd graph && npm run clean # If node has run before remove the old subgraph
	cd graph && npm run start  # (re)start the node [postgres & ipfs & blockchain ingester]
	# npm run codegen

graph-deploy-local-mumbai:
	cd graph && GRAPH_CHAIN=mumbai npm run prepare  
	cd graph && GRAPH_CHAIN=mumbai npm run create-local
	cd graph && GRAPH_CHAIN=mumbai npm run deploy-local  # Send the subgraph to the node (May need delay before this command if graphNode not ready to receive subgraph)

graph-deploy-local-alfajores:
	cd graph && GRAPH_CHAIN=alfajores npm run prepare
	cd graph && GRAPH_CHAIN=alfajores npm run create-local
	cd graph && GRAPH_CHAIN=alfajores npm run deploy-local

graph-deploy-mumbai-test:
	cd graph && GRAPH_CHAIN=mumbai npm run prepare
	cd graph && GRAPH_CHAIN=mumbai GQL_HOST=${GQL_HOST_TEST} npm run create-remote
	cd graph && GRAPH_CHAIN=mumbai GQL_HOST=${GQL_HOST_TEST} npm run deploy-remote

graph-deploy-mumbai-prod:
	cd graph && GRAPH_CHAIN=mumbai npm run prepare
	cd graph && GRAPH_CHAIN=mumbai GQL_HOST=${GQL_HOST_PROD} npm run create-remote
	cd graph && GRAPH_CHAIN=mumbai GQL_HOST=${GQL_HOST_PROD} npm run deploy-remote

graph-deploy-alfajores-test:
	cd graph && GRAPH_CHAIN=alfajores npm run prepare
	cd graph && GRAPH_CHAIN=alfajores GQL_HOST=${GQL_HOST_TEST} npm run create-remote
	cd graph && GRAPH_CHAIN=alfajores GQL_HOST=${GQL_HOST_TEST} npm run deploy-remote

graph-deploy-alfajores-prod:
	cd graph && GRAPH_CHAIN=alfajores npm run prepare
	cd graph && GRAPH_CHAIN=alfajores GQL_HOST=${GQL_HOST_PROD} npm run create-remote
	cd graph && GRAPH_CHAIN=alfajores GQL_HOST=${GQL_HOST_PROD} npm run deploy-remote

