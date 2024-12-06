// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract TransferTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    address public recipient = address(0xcafe);
    uint256 public notaId;

    function setUp() public override {
        super.setUp();
        
        _fundCallerApproveAddress(caller, DAI, 100 ether, address(REGISTRAR));
        notaId = _registrarWriteHelper(caller, address(DAI), 1 ether, 0, owner, HOOK, "");
    }

    function testTransfer() public {
        _registrarTransferAssumptions(owner, owner, recipient, notaId);
        _registrarTransferHelper(owner, owner, recipient, notaId);
    }

    function testTransferApproved() public {
        _registrarApproveHelper(owner, caller, notaId);
        _registrarTransferHelper(caller, owner, recipient, notaId);
    }

    function testTransferOperator() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721.ApprovalForAll(owner, caller, true);
        
        vm.prank(owner);
        REGISTRAR.setApprovalForAll(caller, true);
        _registrarTransferHelper(caller, owner, recipient, notaId);
    }

    function testTransferFailUnauthorized(address unauthorized) public {
        vm.assume(unauthorized != owner);
        vm.assume(unauthorized != REGISTRAR.getApproved(notaId));
        vm.assume(!REGISTRAR.isApprovedForAll(owner, unauthorized));

        vm.expectRevert("NOT_APPROVED_OR_OWNER");
        vm.prank(unauthorized);
        REGISTRAR.transferFrom(owner, recipient, notaId);
    }

    function testFuzzTransfer(address to) public {
        _registrarTransferAssumptions(owner, owner, to, notaId);
        _registrarTransferHelper(owner, owner, to, notaId);
    }
}
