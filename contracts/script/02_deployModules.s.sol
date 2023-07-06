// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol"; 
import "../src/modules/DirectPay.sol";
import "../src/modules/ReversibleRelease.sol";
import "../src/modules/Milestones.sol";
import "../src/libraries/DataTypes.sol";

contract DeployModules is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address DIRECT_PAY = address(new DirectPay(address(0), DataTypes.WTFCFees(0, 0, 0, 0), "ipfs://"));
        console.log(DIRECT_PAY);

        address REVERSIBLE_RELEASE = address(new ReversibleRelease(address(0), DataTypes.WTFCFees(0, 0, 0, 0), "ipfs://"));
        console.log(REVERSIBLE_RELEASE);

        address MILESTONES = address(new Milestones(address(0), DataTypes.WTFCFees(0, 0, 0, 0), "ipfs://"));
        console.log(MILESTONES);

        vm.stopBroadcast();
    }
}