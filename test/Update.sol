// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract UpdateTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    uint256 public notaId;
    
    function setUp() public override {
        super.setUp();
        _fundCallerApproveAddress(caller, DAI, 1 ether, address(REGISTRAR));
        vm.prank(caller);
        notaId = REGISTRAR.write(address(DAI), 1 ether, 0, owner, HOOK, "");
    }

    function testUpdate() public {
        bytes memory hookData = "";
        vm.prank(owner);
        _registrarUpdateHelper(owner, notaId, hookData);
    }

    function testUpdateNonexistentNota() public {
        uint256 nonexistentNotaId = 999;
        bytes memory hookData = "";

        vm.expectRevert(INotaRegistrar.NonExistent.selector);
        REGISTRAR.update(nonexistentNotaId, hookData);
    }
}