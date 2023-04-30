// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Test } from "forge-std/Test.sol";
import {CheqRegistrar} from "../../src/CheqRegistrar.sol";
import "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";


contract CheqRegistrarTest is Test {
    address internal registrarImpl;
    CheqRegistrar public REGISTRAR;

    function setUp() public virtual {
        registrarImpl = address(new CheqRegistrar());
        REGISTRAR = CheqRegistrar(address(new ERC1967Proxy(registrarImpl, abi.encodeWithSignature("initialize()"))));
    }
}
