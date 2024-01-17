import json
import re
import shlex
import subprocess
import sys

"""
Steps to deploy to a new chain:

1. Add the RPC to rpc_for_chain in this file

2. Append chain:rpc to environment/ethereum in docker-compose.yml

3. Run python3 deployDenota [privateKey] [chain]

4. Run export GQL_HOST=server && export GRAPH_CHAIN=chain && make graph-deploy-remote
(Optionally, add new make command for the chain)

5. If neccesary, update chainInfo.ts with info for the new chain and set isDisabled=false

contractAddresses.tsx should automatically have been updated
TODO: figure out how to get nginx wildcard paths working properly, manually add a path for each chain for now
TODO Capture which branch/commit the contracts were deployed from
TODO how to update contract addresses on redeployement
"""

# test


def extract_address(input):
    try:
        return re.search('Deployed to: (.*)', input).group(1)
    except AttributeError:
        sys.exit("Unable to parse contract address")


def eth_call(command, error):
    result = subprocess.run(
        shlex.split(command),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if result.stderr:
        print(error)
        sys.exit(result.stderr)
    return result


chains = ["arbitrum", "alfajores", "base", "bnb",
          "gnosis", "sepolia", "mumbai", "optimism", "zksync"]


def rpc_for_chain(chain):
    chain_rpc = {
        "arbitrum": "https://goerli-rollup.arbitrum.io/rpc",
        "alfajores": "https://alfajores-forno.celo-testnet.org",
        "base": "https://goerli.base.org",
        "bnb": "https://bsc-testnet.publicnode.com",
        "gnosis": "https://rpc.ankr.com/gnosis",  # MAINNET
        # "goerli":  "https://goerli.blockpi.network/v1/rpc/public", # Will be deprecated
        # "https://rpc2.sepolia.org",# "https://endpoints.omniatech.io/v1/eth/sepolia/public",
        "sepolia": "https://eth-sepolia-public.unifra.io",
        "mumbai": "https://polygon-mumbai-bor.publicnode.com",
        "optimism": "https://goerli.optimism.io",
        "zksync": "https://zksync2-testnet.zksync.dev",
        "polygon": "https://polygon-rpc.com/"
    }
    return chain_rpc.get(chain, "http://127.0.0.1:8545")


def native_token_name_chain(chain):
    chain_token_name = {
        "arbitrum": "ETH",
        "alfajores": "CELO",
        "base": "ETH",
        "bnb": "BNB",
        "gnosis": "DAI",
        # "goerli":  "ETH",
        "sepolia": "ETH",
        "mumbai": "MATIC",
        "optimism": "ETH",
        "zksync": "ETH"
    }
    return chain_token_name[chain]


def deploy_libraries(existing_addresses, chain, rpc_key_flags):
    datatypes = "src/libraries/DataTypes.sol:DataTypes"
    library_paths, lib_addresses = [datatypes], []
    for library_path in library_paths:
        name = library_path.split(":")[-1]
        if not existing_addresses[chain][name]:
            result = eth_call(
                f'forge create {library_path} {rpc_key_flags}', "Library deployment failed")
            address = extract_address(result.stdout)
            existing_addresses[chain][name] = str(address)
        else:
            address = existing_addresses[chain][name]
        lib_addresses.append(library_path + ":" + address)
        print(f"{name} library: {address}")
    libraries_flag = f"--libraries {' '.join(lib_addresses)}"
    return libraries_flag


def deploy_registrar_tokens(existing_addresses, chain, rpc_key_flags):
    if not existing_addresses[chain]["registrar"]:
        registar_path = "src/NotaRegistrar.sol:NotaRegistrar"
        result = eth_call(
            f'forge create {registar_path} {rpc_key_flags}', "Registrar deployment failed")
        registrar = extract_address(result.stdout)
        existing_addresses[chain]["registrar"] = registrar
        block_number = (eth_call(
            f'cast block-number --rpc-url {rpc_for_chain(chain)}', "Block failed to fetch")).stdout
        existing_addresses[chain]["startBlock"] = block_number.strip("\n")
    else:
        registrar = existing_addresses[chain]["registrar"]
        block_number = existing_addresses[chain]["startBlock"]
    print(f'Registrar address: {registrar}')

    return existing_addresses, block_number, registrar, newRegistrarDeployed


def deploy_tokens(existing_addresses, chain, rpc_key_flags, newRegistrarDeployed):
    # Deploy ERC20s for testing
    erc20_path, oldTokens, amount = "test/mock/erc20.sol:TestERC20", [], 10_000_000_000_000_000_000_000_000
    for (supply, name, symbol) in [(amount, "weth", "WETH"), (amount, "dai", "DAI")]:
        if not existing_addresses[chain][name]:
            result = eth_call(
                f'forge create {erc20_path} --constructor-args {supply} {name} {symbol} {rpc_key_flags}', "ERC20 deployment failed")
            token = extract_address(result.stdout)
            existing_addresses[chain][name] = token  # TODO use .get() instead?

            eth_call(
                f'cast send {registrar} "whitelistToken(address,bool,string)" {token} "true" {symbol} {rpc_key_flags}', "Whitelist token failed")
        else:
            token = existing_addresses[chain][name]
            oldTokens.append((token, name, symbol))

        print(f'{symbol} address: {token}')

    # Whitelist tokens
    if newRegistrarDeployed:
        for (token, name, symbol) in oldTokens:
            eth_call(
                f'cast send {registrar} "whitelistToken(address,bool,string)" {token} "true" {symbol} {rpc_key_flags}', "Whitelist token failed")

        native_token_name = native_token_name_chain(chain)
        eth_call(
            f'cast send {registrar} "whitelistToken(address,bool,string)" "0x0000000000000000000000000000000000000000" "true" {native_token_name} {rpc_key_flags}', "Whitelist token failed")


def deploy_modules(existing_addresses, chain, rpc_key_flags, registrar):
    # TODO refactor into a for loop
    if not existing_addresses[chain]["directPay"]:
        DirectPay_path = "src/modules/DirectPay.sol:DirectPay"
        result = eth_call(
            f'forge create {DirectPay_path} --constructor-args {registrar} "(0,0,0,0)" "ipfs://" {rpc_key_flags}', "Module deployment failed")
        direct_pay = extract_address(result.stdout)
        existing_addresses[chain]["directPay"] = direct_pay
    else:
        direct_pay = existing_addresses[chain]["directPay"]
    # Update the address JSON
    print(f'DirectPay address: {direct_pay}')
    with open("contractAddresses.json", 'w') as f:
        f.write(json.dumps(existing_addresses))

    if not existing_addresses[chain]["escrow"]:
        Escrow_path = "src/modules/ReversibleRelease.sol:ReversibleRelease"
        result = eth_call(
            f'forge create {Escrow_path} --constructor-args {registrar} "(0,0,0,0)" "ipfs://" {rpc_key_flags}', "Module deployment failed")
        escrow = extract_address(result.stdout)
        existing_addresses[chain]["escrow"] = escrow
    else:
        escrow = existing_addresses[chain]["escrow"]
    # Update the address JSON
    print(f'Escrow address: {escrow}')
    with open("contractAddresses.json", 'w') as f:
        f.write(json.dumps(existing_addresses))
    return existing_addresses


def deploy_coverage(existing_addresses, chain, rpc_key_flags, registrar):
    usdc_address = existing_addresses[chain]["usdc"]
    if not existing_addresses[chain]["coverage"]:
        Coverage_path = "src/modules/Coverage.sol:Coverage"
        result = eth_call(
            f'forge create {Coverage_path} --constructor-args {registrar} "(0,0,0,0)" "ipfs://" {usdc_address} {rpc_key_flags}', "Module deployment failed")
        coverage = extract_address(result.stdout)
        existing_addresses[chain]["coverage"] = coverage
        # Whitelist the Escrow module
        eth_call(
            f'cast send {registrar} "whitelistModule(address,bool,bool,string)" {coverage} "false" "true" "Coverage" {rpc_key_flags}', "Whitelist module failed")

    # Update the address JSON
    print(f'Coverage address: {coverage}')
    with open("contractAddresses.json", 'w') as f:
        f.write(json.dumps(existing_addresses))
    return existing_addresses


def deploy_axelar(existing_addresses, chain, rpc_key_flags, registrar):
    """
        Deploys directpay on `chain`
        Deploys Axelar sender, and reciever on all chains
        Returns the addresses
    """
    gateway = existing_addresses[chain]["AxelarGateway"]
    gas_station = existing_addresses[chain]["AxelarGasStation"]

    # AxelarDirectPay module
    if not existing_addresses[chain]["directPayAxelar"]:
        axelarDirectPay_path = "src/modules/AxelarDirectPay.sol:AxelarDirectPay"
        result = eth_call(
            f'forge create {axelarDirectPay_path} --constructor-args {registrar} "(0,0,0,0)" "ipfs://" {gateway} {rpc_key_flags}', "Axelar Module deployment failed")
        direct_pay_axelar = extract_address(result.stdout)
        existing_addresses[chain]["directPayAxelar"] = direct_pay_axelar
    else:
        direct_pay_axelar = existing_addresses[chain]["directPayAxelar"]

    # BridgeSender
    if not existing_addresses[chain]["bridgeSender"]:
        axelarBridgeSender_path = "src/axelar/BridgeSender.sol:BridgeSender"
        result = eth_call(
            f'forge create {axelarBridgeSender_path} --constructor-args {gateway} {gas_station} {rpc_key_flags}', "BridgeSender deployment failed")
        axelarBridgeSender = extract_address(result.stdout)
        existing_addresses[chain]["bridgeSender"] = axelarBridgeSender
    else:
        axelarBridgeSender = existing_addresses[chain]["bridgeSender"]

    # BridgeReceiver
    if not existing_addresses[chain]["bridgeReceiver"]:
        axelarBridgeReceiver_path = "src/axelar/bridgeReceiver.sol:BridgeReceiver"
        result = eth_call(
            f'forge create {axelarBridgeReceiver_path} --constructor-args {gateway} {gas_station} {registrar} {direct_pay_axelar} {rpc_key_flags}', "BridgeReceiver deployment failed")
        axelarBridgeReceiver = extract_address(result.stdout)
        existing_addresses[chain]["bridgeReceiver"] = axelarBridgeReceiver
    else:
        axelarBridgeReceiver = existing_addresses[chain]["bridgeReceiver"]
    return existing_addresses, axelarBridgeSender, axelarBridgeReceiver


def create_crosschain_nota(existing_addresses, chain, rpc_key_flags):
    """
    Use bridgeSender to send value on source chain and create Nota on Polygon Mumbai (for now)
    """
    # send tx to bridgeSender->registrar->module --> relayer --> bridgeReceiver->registrar->module)
    if chain == "alfajores":
        owner, memoURI_, imageURI_ = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "", ""
        destinationChain, destinationAddress = "Polygon", existing_addresses[
            "mumbai"]["bridgeReceiver"]
        call = f"cast send '{axelarBridgeSender}' 'createRemoteNota(address,uint256,address,string calldata,string calldata,string calldata,string calldata)' '0x0000000000000000000000000000000000000000' '100' '{owner}' '{memoURI_}' '{imageURI_}' '{destinationChain}' '{destinationAddress}' {rpc_key_flags} --value '5000'"
        print(call)
        eth_call(call, "Crosschain Nota creation failed")


if __name__ == "__main__":
    key = sys.argv[1]  # load up from from the .env file directly?
    for chain in ["polygon"]:  # "mumbai",
        print(f"\n{chain} @{rpc_for_chain(chain)}")
        rpc_key_flags = f"--private-key {key} --rpc-url {rpc_for_chain(chain)} --gas-price 400gwei"
        with open("contractAddresses.json", 'r') as f:
            existing_addresses = json.loads(f.read())

        libraries_flag = deploy_libraries(
            existing_addresses, chain, rpc_key_flags)
        existing_addresses, block_number, registrar = deploy_registrar_tokens(
            existing_addresses, chain, rpc_key_flags)

        if chain == "polygon":
            deploy_coverage(existing_addresses, chain,
                            rpc_key_flags, registrar)
            deploy_modules(existing_addresses, chain, rpc_key_flags, registrar)
        else:
            deploy_modules(existing_addresses, chain, rpc_key_flags, registrar)
            deploy_axelar(existing_addresses, chain, rpc_key_flags, registrar)
            create_crosschain_nota(existing_addresses, chain, rpc_key_flags)

        with open("contractAddresses.json", 'w') as f:
            f.write(json.dumps(existing_addresses))

        with open("../graph/subgraph/config/" + chain + ".json", 'w') as f:
            existing_addresses[chain]["network"] = chain
            f.write(json.dumps(existing_addresses[chain]))

        # Query for the tokenURI
        # print(
        #     f"cast call {registrar} 'tokenURI(uint256)' '0' --rpc-url {rpc}")
