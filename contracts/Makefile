-include .env

num_optimizations=1000000
create2_factory_address=0x0000000000FFe8B47B3e2130213B802212439497

testDai=0xc5B6c09dc6595Eb949739f7Cd6A8d542C2aabF4b
testEth=0xe37F99b03C7B4f4d71eE20e8eF3AC4E138D47F80
denotaContractURI='{"name":"Denota Protocol (beta)","description":"Welcome to the future of programmable crypto payments! Imagine a world where your payments arent just transactions, but smart, programmable assets. From trustless betting to reversibility and multi-step payments, Denotas Nota NFTs revolutionize how you send funds.With Denota, each payment is an NFT, capable of carrying custom rules and data for your unique needs. Theyre not just payments; theyre fully onchain, extensible, composable, and transferable payment agreements. Explore our simple yet powerful payment hooks to deploy your own and start generating revenue!","image":"ipfs://QmZfdTBo6Pnr7qbWg4FSeSiGNHuhhmzPbHgY7n8XrZbQ2v","banner_image":"ipfs://QmVT5v2TGLuvNDcyTv9hjdga2KAnv37yFjJDYsEhGAM2zQ","external_link":"denota.xyz","collaborators":["almaraz.eth","0xrafi.eth","pengu1689.eth"]}'#
DEPLOY_RPC_URL=${POLYGON_RPC_URL} #
VERIFIER_URL=https://api.polygonscan.com/api/
# put argsWrite() in ModuleBase that takes the separate bytes arguments and encodes them into a single bytes?

# TODO create make script that mines salt then calls `forge script --verify` for deployment
# TODO make script switch vars depending on chainId
# TODO SDK like helpers

deploy-all:
	make deploy-registrar-salt
	make whitelist-tokens
	make deploy-module-salt

# Need to check if the salt already exists to skip mining it
deploy-registrar-salt:
	# "brew install jq" if needed
	forge flatten src/NotaRegistrar.sol > src/flat/Denota.sol
	forge compile --optimizer-runs ${num_optimizations}

	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' out/flat/Denota.sol/NotaRegistrar.json)$${constructorArgs} ; \
	cast create2 --deployer ${create2_factory_address} --init-code $${bytecode} --starts-with 00000000 --caller ${ADDRESS} 2>&1 | tee registrarSalt.txt ; \
	salt=$$(cat registrarSalt.txt | grep "Salt: " | awk '{print $$2}') ; \
	contractAddress=$$(cat registrarSalt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${create2_factory_address} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}; \
	forge verify-contract --num-of-optimizations ${num_optimizations} --compiler-version v0.8.20+commit.a1b79de6 --watch \
	--constructor-args $${constructorArgs} \
	--chain-id 137 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	$${contractAddress} \
	src/flat/Denota.sol:NotaRegistrar

setURI:
	cast send $${contractAddress} "setContractURI(string)" ${denotaContractURI} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}

whitelist-tokens:
	registrarAddress=$$(cat registrarSalt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send $${registrarAddress} "whitelistToken(address,bool)" ${testEth} true --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ; \
	cast send ${testDai} "approve(address,uint256)" $${registrarAddress} 1000000000000000000000000 --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ; \
	cast send ${testEth} "approve(address,uint256)" $${registrarAddress} 1000000000000000000000000 --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}

# Need to save module address here (and depend on chainId)
moduleFileName=ReversibleRelease
deploy-module-salt:
	forge flatten src/modules/$(moduleFileName).sol > src/flat/$(moduleFileName).sol
	forge compile --optimizer-runs ${num_optimizations}

	registrarAddress=$$(cat registrarSalt.txt | grep "Address: " | awk '{print $$2}') ; \
	constructorArgs=$$(cast abi-encode "constructor(address)" $${registrarAddress}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' out/flat/$(moduleFileName).sol/$(moduleFileName)Payment.json)$${constructorArgs} ; \
	cast create2 --deployer ${create2_factory_address} --init-code $${bytecode} --starts-with 00000000 --caller ${ADDRESS} 2>&1 | tee ReversibleRelease_salt.txt ; \
	salt=$$(cat ReversibleRelease_salt.txt | grep "Salt: " | awk '{print $$2}') ; \
	moduleAddress=$$(cat ReversibleRelease_salt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${create2_factory_address} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ; \
	sleep 10 ; \
	forge verify-contract --compiler-version v0.8.20+commit.a1b79de6 --num-of-optimizations ${num_optimizations} --watch \
	--chain-id 137 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	--constructor-args $${constructorArgs} \
	$${moduleAddress} \
	src/flat/$(moduleFileName).sol:$(moduleFileName)Payment ; \
	cast send $${registrarAddress} "whitelistModule(address,bool)" $${moduleAddress} true --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ; \
	cast send $${registrarAddress} "write(address,uint256,uint256,address,address,bytes)" 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 1000 0 0xd20e342db297646a500a980088723c9e8af9810d $${contractAddress} "0x0000000000000000000000000x374E4F9EF906F3e51df1b3305936Ec18A6797748000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000001e68747470733a2f2f747769747465722e636f6d2f44656e6f74614c61627300000000000000000000000000000000000000000000000000000000000000000042697066733a2f2f62616679626569647a7871787272633376616f7a797870616c34716872726f646f7035747775797769767778706e64796865613337776973357771000000000000000000000000000000000000000000000000000000000000" --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}

# reversibleReleaseBytes=$$(cast abi-encode "(address,string,string)" "") ; 
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