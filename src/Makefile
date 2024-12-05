-include ../.env

FACTORY_ADDRESS=0x0000000000FFe8B47B3e2130213B802212439497
DEPLOY_RPC_URL=${POLYGON_RPC_URL}
VERIFIER_URL=https://api.polygonscan.com/api/  # https://api-sepolia.etherscan.io/api
optimizer_runs=1000000

ADDRESS_LOCAL=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
PRIVATE_KEY_LOCAL=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
FACTORY_ADDRESS_LOCAL=0x5FbDB2315678afecb367f032d93F642f64180aa3
DEPLOY_RPC_URL_LOCAL=127.0.0.1:8545

# "brew install jq" if needed
# `anvil` in a separate terminal to run the local chain
deploy-all-local: deploy-factory-local deploy-token-local deploy-registrar-local deploy-hook-local write-local tokenURI-local

deploy-factory-local:
	forge create --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL} src/ImmutableCreate2Factory.sol:ImmutableCreate2Factory --optimizer-runs ${optimizer_runs}

deploy-token-local:
	forge create --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL} test/mock/MockERC20.sol:MockERC20 --constructor-args "Dai" "DAI" 18 --optimizer-runs ${optimizer_runs}

# 0.5hrs for 9 zeros base M1 air
mine-registrar-local:
	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS_LOCAL}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' ../out/NotaRegistrar.sol/NotaRegistrar.json)$${constructorArgs} ; \
	cast create2 --deployer ${FACTORY_ADDRESS_LOCAL} --init-code $${bytecode} --starts-with 000 --caller ${ADDRESS_LOCAL} 2>&1 | tee NotaRegistrar.salt.txt ; \
	echo $$(cat NotaRegistrar.salt.txt | grep "Salt: " | awk '{print $$2}') ;

# Paste this in from the output of the above command if registrar code changes
salt=0xf39fd6e51aad88f6f4ce6ab8827279cfffb922669edd78cd0fa5eb199a9625d6
deploy-registrar-local:
	forge build --optimizer-runs ${optimizer_runs}

	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS_LOCAL}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' ../out/NotaRegistrar.sol/NotaRegistrar.json)$${constructorArgs} ; \
	cast send ${FACTORY_ADDRESS_LOCAL} "safeCreate2(bytes32,bytes calldata)" ${salt} $${bytecode} --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL};

# Paste from salt file if registrar code changes
registrarAddress=0xf403c90302365f14a0e536875d908001cedf1ef5
deploy-hook-local:
	forge create --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL} test/mock/MockHook.sol:MockHook --constructor-args ${registrarAddress} --optimizer-runs ${optimizer_runs}

writeSelector="write(address,uint256,uint256,address,address,bytes)"
currency=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 # deployed token address
escrow=100
instant=0
owner=0x70997970C51812dc3A010C7d01b50e0d17dc79C8 # Send to a different account since self sends will first depricate balance and revert without double amount
hook=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
hookData=0x
write-local:
	cast send ${currency} "mint(address,uint256)" ${ADDRESS_LOCAL} ${escrow} --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL} ; \
	cast send ${currency} "approve(address,uint256)" ${registrarAddress} ${escrow} --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL} ; \
	cast send ${registrarAddress} ${writeSelector} ${currency} ${escrow} ${instant} ${owner} ${hook} ${hookData} --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL}

tokenURI-local:
	cast call ${registrarAddress} "tokenURI(uint256)" 1 --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL}

# Welcome to the future of programmable crypto payments! Imagine a world where your payments arent just transactions, but smart, programmable assets. From trustless betting to reversibility and multi-step payments, Denotas Nota NFTs revolutionize how you send funds. With Denota, each payment is an NFT, capable of carrying custom rules and data for your unique needs. Theyre not just payments; theyre fully onchain, extensible, composable, and transferable payment agreements. Explore our simple yet powerful payment hooks to deploy your own and start generating revenue!
# Fully programmable payments with rich metadata for users and a development platform with hooks for developers.
setURI-local:
	denotaContractURI="{'name':'Denota Protocol (beta)','description':'The Programmable Escrow Protocol','image':'ipfs://QmZfdTBo6Pnr7qbWg4FSeSiGNHuhhmzPbHgY7n8XrZbQ2v','banner_image':'ipfs://QmVT5v2TGLuvNDcyTv9hjdga2KAnv37yFjJDYsEhGAM2zQ','external_link':'denota.xyz','collaborators':['almaraz.eth']}"; \
	cast send ${registrarAddress} "setContractURI(string)" "$${denotaContractURI}" --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL}

getURI-local:
		URI=$$(cast call ${registrarAddress} "contractURI()" --private-key ${PRIVATE_KEY_LOCAL} --rpc-url ${DEPLOY_RPC_URL_LOCAL}) ; \
		cast abi-decode "f(bytes)(string)" $${URI}

######################################################################################################################################################
#    																	Mainnet																		 #	
######################################################################################################################################################
deploy-registrar:
	forge compile --optimizer-runs ${optimizer_runs}

	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' ../out/NotaRegistrar.sol/NotaRegistrar.json)$${constructorArgs} ; \
	cast create2 --deployer ${FACTORY_ADDRESS} --init-code $${bytecode} --starts-with 000 --caller ${ADDRESS} 2>&1 | tee NotaRegistrar.salt.txt ; \
	salt=$$(cat NotaRegistrar.salt.txt | grep "Salt: " | awk '{print $$2}') ;
	contractAddress=$$(cat NotaRegistrar.salt.txt | grep "Address: " | awk '{print $$2}') ; 
	cast send ${FACTORY_ADDRESS} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL};

verify-registrar:
	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	forge verify-contract --num-of-optimizations ${optimizer_runs} --compiler-version v0.8.24 --watch \
	--constructor-args $${constructorArgs} \
	--chain-id 11155111 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${ETHER_SCAN_API_KEY} \
	0x00002bCC9B3e92a59207C43631f3b407AE5bBd0B \
	src/NotaRegistrar.sol:NotaRegistrar

# Note: sometimes verification is skipped if block times are slow (testnets)
deploy-verify:
	forge compile --optimizer-runs ${optimizer_runs}

	constructorArgs=$$(cast abi-encode "constructor(address)" ${ADDRESS}) ; \
	constructorArgs=$$(echo $${constructorArgs} | sed 's/0x//') ; \
	bytecode=$$(jq -r '.bytecode.object' ../out/NotaRegistrar.sol/NotaRegistrar.json)$${constructorArgs} ; \
	cast create2 --deployer ${FACTORY_ADDRESS} --init-code $${bytecode} --starts-with 00000000 --caller ${ADDRESS} 2>&1 | tee NotaRegistrar.salt.txt ; \
	salt=$$(cat src/NotaRegistrar.salt.txt | grep "Salt: " | awk '{print $$2}') ; \
	contractAddress=$$(cat src/NotaRegistrar.salt.txt | grep "Address: " | awk '{print $$2}') ; \
	cast send ${FACTORY_ADDRESS} "safeCreate2(bytes32,bytes calldata)" $${salt} $${bytecode} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}; \
	forge verify-contract --num-of-optimizations ${optimizer_runs} --compiler-version v0.8.24 --watch \
	--constructor-args $${constructorArgs} \
	--chain-id 137 --verifier-url ${VERIFIER_URL} --etherscan-api-key ${ETHER_SCAN_API_KEY} \
	$${contractAddress} \
	src/NotaRegistrar.sol:NotaRegistrar

setURI:
	contractAddress=$$(cat src/NotaRegistrar.salt.txt | grep "Address: " | awk '{print $$2}') ; \
	denotaContractURI="{'name':'Denota Protocol (beta)','description':'The Programmable Escrow Protocol','image':'ipfs://QmZfdTBo6Pnr7qbWg4FSeSiGNHuhhmzPbHgY7n8XrZbQ2v','banner_image':'ipfs://QmVT5v2TGLuvNDcyTv9hjdga2KAnv37yFjJDYsEhGAM2zQ','external_link':'denota.xyz','collaborators':['almaraz.eth']}"; \
	cast send $${contractAddress} "setContractURI(string)" "${denotaContractURI}"" --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL}


# Polygon addresses
CircleUSDC=0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359
USDCe=0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
WETH=0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
ENS=0xbD7A5Cf51d22930B8B3Df6d834F9BCEf90EE7c4f
DAI=0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063
GET=0xdb725f82818De83e99F1dAc22A9b5B51d3d04DD4

writeSelector="write(address,uint256,uint256,address,address,bytes)"
currency=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 # deployed token address
escrow=100
instant=0
owner=${ADDRESS}
hook=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
hookData=0x
write:
	cast send ${currency} "mint(address,uint256)" ${owner} ${escrow} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ; \
	cast send ${currency} "approve(address,uint256)" ${registrarAddress} ${escrow} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ; \
	cast send ${registrarAddress} ${writeSelector} ${currency} ${escrow} ${instant} ${owner} ${hook} ${hookData} --private-key ${PRIVATE_KEY} --rpc-url ${DEPLOY_RPC_URL} ;

test-registrar:
	forge test --gas-report --optimizer-runs ${optimizer_runs} | grep -A 1000 "src/NotaRegistrar.sol:NotaRegistrar contract" | grep -v "Ran [0-9]* test suites" | tee NotaRegistrar.gas.txt | tr -d '\r';