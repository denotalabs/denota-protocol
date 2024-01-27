-include .env

optimizer_runs=1000000
FACTORY_ADDRESS=0x0000000000FFe8B47B3e2130213B802212439497

testDai=0xc5B6c09dc6595Eb949739f7Cd6A8d542C2aabF4b
testEth=0xe37F99b03C7B4f4d71eE20e8eF3AC4E138D47F80
realUSDC=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
USDCe=0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359
denotaContractURI='{"name":"Denota Protocol (beta)","description":"Welcome to the future of programmable crypto payments! Imagine a world where your payments arent just transactions, but smart, programmable assets. From trustless betting to reversibility and multi-step payments, Denotas Nota NFTs revolutionize how you send funds.With Denota, each payment is an NFT, capable of carrying custom rules and data for your unique needs. Theyre not just payments; theyre fully onchain, extensible, composable, and transferable payment agreements. Explore our simple yet powerful payment hooks to deploy your own and start generating revenue!","image":"ipfs://QmZfdTBo6Pnr7qbWg4FSeSiGNHuhhmzPbHgY7n8XrZbQ2v","banner_image":"ipfs://QmVT5v2TGLuvNDcyTv9hjdga2KAnv37yFjJDYsEhGAM2zQ","external_link":"denota.xyz","collaborators":["almaraz.eth","0xrafi.eth","pengu1689.eth"]}'#
DEPLOY_RPC_URL=${POLYGON_RPC_URL} #
VERIFIER_URL=https://api.polygonscan.com/api/

# 0.5hrs for 9 zeros
deploy-all:
	make deploy-registrar-salt
	make whitelist-tokens
	make deploy-module-salt

deploy-registrar:
	# "brew install jq" if needed
	forge flatten src/NotaRegistrar.sol > src/flat/Denota.sol
	forge compile --optimizer-runs ${optimizer_runs}

	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' out/flat/Denota.sol/NotaRegistrar.json)$${constructorArgs} ; \
	cast create2 --deployer ${FACTORY_ADDRESS} --init-code $${bytecode} --starts-with 00000000 --caller ${ADDRESS} 2>&1 | tee salts/registrarSalt.txt ; \
	salt=$$(cat salts/registrarSalt.txt | grep "Salt: " | awk '{print $$2}') ; \
	contractAddress=$$(cat salts/registrarSalt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${FACTORY_ADDRESS} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}; \
	forge verify-contract --num-of-optimizations ${optimizer_runs} --compiler-version v0.8.20+commit.a1b79de6 --watch \
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


moduleFileName=DirectSend
deploy-module:
	forge flatten src/modules/$(moduleFileName).sol > src/flat/$(moduleFileName).sol
	forge compile --optimizer-runs ${optimizer_runs}

	set -e ; \
	registrarAddress=$$(cat salts/registrarSalt.txt | grep "Address: " | awk '{print $$2}') ; \
	constructorArgs=$$(cast abi-encode "constructor(address)" $${registrarAddress}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	echo $${constructorArgs} ; \
	bytecode=$$(jq -r '.bytecode.object' out/flat/$(moduleFileName).sol/$(moduleFileName).json)$${constructorArgs} ; \
	echo $${bytecode} ; \
	cast create2 --deployer ${FACTORY_ADDRESS} --init-code $${bytecode} --starts-with 0000000 --caller ${ADDRESS} 2>&1 | tee salts/$(moduleFileName).txt ; \
	echo "\n\n" ; \
	salt=$$(cat salts/$(moduleFileName).txt | grep "Salt: " | awk '{print $$2}') ; \
	moduleAddress=$$(cat salts/$(moduleFileName).txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${FACTORY_ADDRESS} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}; \
	echo "Address deployed on blockchain.\nVerifying...\n\n" ; \
	sleep 10 ; \
	forge verify-contract --compiler-version v0.8.20+commit.a1b79de6 --num-of-optimizations ${optimizer_runs} --watch \
	--chain-id 137 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	--constructor-args $${constructorArgs} \
	$${moduleAddress} \
	src/flat/$(moduleFileName).sol:$(moduleFileName) ; \
	echo "Contract verified.\nWhitelisting:\n\n" ; \
	cast send $${registrarAddress} "whitelistModule(address,bool)" $${moduleAddress} true --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ; \
	echo "Hook whitelisted.\nWriting:\n\n" ; \
	cast send $${registrarAddress} "write(address,uint256,uint256,address,address,bytes)" ${realUSDC} 0 1000 0xd20e342db297646a500a980088723c9e8af9810d $${moduleAddress} "0x00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000001668747470733a2f2f6170702e64656e6f74612e78797a00000000000000000000000000000000000000000000000000000000000000000000000000000000004168747470733a2f2f692e736561646e2e696f2f6763732f66696c65732f64303962663663343134333738636438326666316263323838366663633638622e706e6700000000000000000000000000000000000000000000000000000000000000" --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}

send-SimpleCash:
	# Make sure approvals are set #

	registrarAddress=$$(cat salts/registrarSalt.txt | grep "Address: " | awk '{print $$2}') ; \
	writeABI="write(address,uint256,uint256,address,address,bytes)" ; \
	currency=${USDCe} ; \
	escrow=0 ; \
	instant=0 ; \
	owner=0x; \
	module=0x000000000AE1D0831c0C7485eAcc847D2F57EBb9; \
	externalURL="https://app.denota.xyz/"; \
	imageURL="ipfs://"; \
	moduleBytes=$$(cast abi-encode "f(string,string)" $${externalURL} $${imageURL}) ; \
	cast send $${registrarAddress} $${writeABI} $${currency} $${escrow} $${instant} $${owner} $${module} $${moduleBytes} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}

all: clean remove install update solc build

fresh-install:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	foundryup
	# make install  # forge build installs these

build  :; forge clean && forge build --optimizer-runs 1000000

solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

# Install the Modules
install :; 
	forge install foundry-rs/forge-std
	forge install dapphub/ds-test --no-commit
	forge install OpenZeppelin/openzeppelin-contracts --no-commit
	forge install axelarnetwork/axelar-gmp-sdk-solidity --no-commit