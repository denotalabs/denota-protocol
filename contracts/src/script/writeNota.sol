// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../modules/SimpleCash.sol";
import "../NotaRegistrar.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "../../test/mock/erc20.sol";


contract SendNota is Script {
    NotaRegistrar immutable registrar = NotaRegistrar(0x000000003C9C54B98C17F5A8B05ADca5B3B041eD);
    INotaModule immutable simpleCash = INotaModule(0x000000000AE1D0831c0C7485eAcc847D2F57EBb9);
    TestERC20 immutable usdc = TestERC20(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359);  // official?

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(deployerPrivateKey);
        console.log("Deployer address: %s", account);

        vm.startBroadcast(deployerPrivateKey);
        IERC20 currency = usdc; 
        uint256 escrowed = 2 * 10**6;
        uint256 instant = 0;
        address owner = 0x4A16a45003652A4c7899eD097341d0A1c76e5D17;
        INotaModule module = simpleCash;
        bytes memory moduleBytes = abi.encode("");

        currency.approve(address(registrar), escrowed+instant);

        uint256 newNotaId = registrar.write(address(currency), escrowed, instant, owner, module, moduleBytes);
        console.log(registrar.tokenURI(newNotaId));
        require(false);        
        vm.stopBroadcast();
    }
}