// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../NotaRegistrar.sol";

interface ImmutableCreate2Factory {
    function safeCreate2(bytes32 salt, bytes calldata initCode) external payable returns (address deploymentAddress);
    function findCreate2Address(bytes32 salt, bytes calldata initCode)
        external
        view
        returns (address deploymentAddress);
    function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash)
        external
        view
        returns (address deploymentAddress);
}

contract DeployRegistrar is Script {
    ImmutableCreate2Factory immutable factory = ImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);
    bytes initCode = type(NotaRegistrar).creationCode;

    bytes32 salt = 0x0;
    address vanity = address(0);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(deployerPrivateKey);
        console.log("Deployer address: %s", account);

        vm.startBroadcast(deployerPrivateKey);

        address registrar = factory.safeCreate2(salt, initCode);
        console.log(registrar);
        require(registrar == vanity, "Registrar address does not match");

        vm.stopBroadcast();
    }
}
