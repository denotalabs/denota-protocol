-include .env

all: clean remove install update solc build

fresh-install:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	foundryup

solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

build  :; forge clean && forge build --optimizer-runs 1000000

install :; 
	forge install foundry-rs/forge-std
	forge install OpenZeppelin/openzeppelin-contracts --no-commit


optimizer_runs=1000000
FACTORY_ADDRESS=0x0000000000FFe8B47B3e2130213B802212439497

CircleUSDC=0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359
USDCe=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
WETH=0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
ENS=0xbD7A5Cf51d22930B8B3Df6d834F9BCEf90EE7c4f
DAI=0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
GET=0xdb725f82818De83e99F1dAc22A9b5B51d3d04DD4
DEPLOY_RPC_URL=${POLYGON_RPC_URL}
VERIFIER_URL=https://api.polygonscan.com/api/

# 0.5hrs for 9 zeros
deploy-all:
	make deploy-registrar-salt

deploy-registrar:
	# "brew install jq" if needed
	forge compile --optimizer-runs ${optimizer_runs}

	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' out/NotaRegistrar.sol/NotaRegistrar.json)$${constructorArgs} ; \
	cast create2 --deployer ${FACTORY_ADDRESS} --init-code $${bytecode} --starts-with 00000000 --caller ${ADDRESS} 2>&1 | tee salts/registrarSalt.txt ; \
	salt=$$(cat salts/registrarSalt.txt | grep "Salt: " | awk '{print $$2}') ; \
	contractAddress=$$(cat salts/registrarSalt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${FACTORY_ADDRESS} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}; \
	forge verify-contract --num-of-optimizations ${optimizer_runs} --compiler-version v0.8.24 --watch \
	--constructor-args $${constructorArgs} \
	--chain-id 137 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${POLYGON_SCAN_API_KEY} \
	$${contractAddress} \
	src/NotaRegistrar.sol:NotaRegistrar

setURI:
	denotaContractURI='{"name":"Denota Protocol (beta)","description":"Welcome to the future of programmable crypto payments! Imagine a world where your payments arent just transactions, but smart, programmable assets. From trustless betting to reversibility and multi-step payments, Denotas Nota NFTs revolutionize how you send funds.With Denota, each payment is an NFT, capable of carrying custom rules and data for your unique needs. Theyre not just payments; theyre fully onchain, extensible, composable, and transferable payment agreements. Explore our simple yet powerful payment hooks to deploy your own and start generating revenue!","image":"ipfs://QmZfdTBo6Pnr7qbWg4FSeSiGNHuhhmzPbHgY7n8XrZbQ2v","banner_image":"ipfs://QmVT5v2TGLuvNDcyTv9hjdga2KAnv37yFjJDYsEhGAM2zQ","external_link":"denota.xyz","collaborators":["almaraz.eth","0xrafi.eth","pengu1689.eth"]}'#; \
	cast send $${contractAddress} "setContractURI(string)" ${denotaContractURI} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}