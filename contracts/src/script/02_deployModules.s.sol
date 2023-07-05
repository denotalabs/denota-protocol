// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol"; 
import "../modules/DirectPay.sol";
import "../modules/ReversibleRelease.sol";
import "../modules/Milestones.sol";

contract DeployModules is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // address registrar = address(new NotaRegistrar());
        // console.log(registrar);

        vm.stopBroadcast();
    }
}