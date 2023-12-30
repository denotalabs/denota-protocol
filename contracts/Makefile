-include .env

num_optimizations=1000000
create2_factory_address=0x0000000000FFe8B47B3e2130213B802212439497
registrarAddress=0x000000002Da990d5DC06Fb325dcac930734ae33e

# TODO make verification multi-part since it's so long for block explorer users to find the right part
# put argsWrite() in ModuleBase that takes the separate bytes arguments and encodes them into a single bytes
# remove the libraries from foundry bc they show up in the verification

deploy-registrar-salt:
	# "brew install jq" if needed
	forge flatten src/NotaRegistrar.sol > src/flat/Denota.sol
	forge compile --optimizer-runs ${num_optimizations}

	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' out/Denota.sol/NotaRegistrar.json)$${constructorArgs} ; \
	cast create2 --deployer ${create2_factory_address} --init-code $${bytecode} --starts-with 00000000 --caller ${ADDRESS} 2>&1 | tee salt.txt ; \
	salt=$$(cat salt.txt | grep "Salt: " | awk '{print $$2}') ; \
	contractAddress=$$(cat salt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${create2_factory_address} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${MUMBAI_RPC_URL} ; \
	sleep 5 ; \
	sleep 10 ; \
	forge verify-contract \
	--chain-id 80001 \
	--num-of-optimizations ${num_optimizations} \
	--watch \
	--verifier-url https://api-testnet.polygonscan.com/api/ \
	--etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	--compiler-version v0.8.20+commit.a1b79de6 \
	--constructor-args $${constructorArgs} \
	$${contractAddress} \
	src/flat/Denota.sol:NotaRegistrar

# Need to save module address here (and depend on chainId)
moduleFileName=ReversibleRelease
deploy-module-salt:
	forge flatten src/modules/$(moduleFileName).sol > src/flat/$(moduleFileName).sol
	forge compile --optimizer-runs ${num_optimizations}

	constructorArgs=$$(cast abi-encode "constructor(address)" ${registrarAddress}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' out/flat/$(moduleFileName).sol/$(moduleFileName)Payment.json)$${constructorArgs} ; \
	cast create2 --deployer ${create2_factory_address} --init-code $${bytecode} --starts-with 000000 --caller ${ADDRESS} 2>&1 | tee salt2.txt ; \
	salt=$$(cat salt2.txt | grep "Salt: " | awk '{print $$2}') ; \
	contractAddress=$$(cat salt2.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${create2_factory_address} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${MUMBAI_RPC_URL} ; \
	sleep 10 ; \
	forge verify-contract \
	--chain-id 80001 \
	--num-of-optimizations ${num_optimizations} \
	--watch \
	--verifier-url https://api-testnet.polygonscan.com/api/ \
	--etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	--compiler-version v0.8.20+commit.a1b79de6 \
	--constructor-args $${constructorArgs} \
	$${contractAddress} \
	src/flat/$(moduleFileName).sol:$(moduleFileName)Payment


# What I learned: creation bytecode != deployed bytecode. Creation includes the constructor opcodes in the first section, deployed bytecode in the middle, then constructor args in the last section if they aren't hardcoded

all: clean remove install update solc build 

# Install Foundry, node packages, and foundry libraries
fresh-install:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	foundryup
	# make install  # forge build installs these

# Compiles the contracts
build  :; forge clean && forge build --optimize --optimizer-runs 1000000

deploy-local:
	python3 deployDenota.py ${PRIVATE_KEY}
	
deploy-testnets:
	python3 deployDenota.py ${PRIVATE_KEY}

create-mumbai-data: # write notas from different modules, transfer, fund, cash
	python3 createNotas.py ${PRIVATE_KEY} "mumbai"



# Install proper solc version.
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

# Install the Modules
install :; 
	forge install foundry-rs/forge-std
	forge install dapphub/ds-test --no-commit
	forge install OpenZeppelin/openzeppelin-contracts --no-commit
	forge install axelarnetwork/axelar-gmp-sdk-solidity --no-commit