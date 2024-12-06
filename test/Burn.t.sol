// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract BurnTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    uint256 public notaId;

    function setUp() public override {
        super.setUp();
        
        _fundCallerApproveAddress(caller, DAI, 100, address(REGISTRAR));
        notaId = _registrarWriteHelper(caller, address(DAI), 100, 0, owner, HOOK, "");
    }

    function testBurn() public {
        _registrarBurnHelper(owner, notaId, "");
    }

    function testFuzzBurn(bytes calldata hookData) public {
        _registrarBurnHelper(owner, notaId, hookData);
    }

    function testBurnByApproved() public {
        address approved = address(0x1234);

        _registrarApproveHelper(owner, approved, notaId);
        _registrarBurnHelper(approved, notaId, "");
    }

    function testBurnByOperator() public {
        address operator = address(0x5678);
        
        vm.prank(owner);
        REGISTRAR.setApprovalForAll(operator, true);
        
        _registrarBurnHelper(operator, notaId, "");
    }

    function testBurnNotOwnerOrApproved() public {
        address notApproved = address(0x1234);

        vm.expectRevert("NOT_APPROVED_OR_OWNER");
        vm.prank(notApproved);
        REGISTRAR.burn(notaId, "");
    }
}
