// SPDX-License-Identifier: BLS-1.0
pragma solidity ^0.8.13;

import "forge-std/Script.sol"; 
import "../src/NotaRegistrar.sol";
import "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployRegistrar is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address registrarImpl = address(new NotaRegistrar());
        address REGISTRAR = address(NotaRegistrar(address(new ERC1967Proxy(registrarImpl, abi.encodeWithSignature("initialize()")))));
        console.log(REGISTRAR);

        vm.stopBroadcast();
    }
}