// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol"; 
import "../NotaRegistrar.sol";

contract DeployRegistrar is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        vm.startBroadcast();

        NotaRegistrar registrar = new NotaRegistrar();

        vm.stopBroadcast();
    }
}