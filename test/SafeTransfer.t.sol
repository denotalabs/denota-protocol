// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract SafeTransferTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    address public recipient = address(0xcafe);
    uint256 public notaId;

    function setUp() public override {
        super.setUp();
        
        _fundCallerApproveAddress(caller, DAI, 100 ether, address(REGISTRAR));
        notaId = _registrarWriteHelper(caller, address(DAI), 1 ether, 0, owner, HOOK, "");
    }

    function testSafeTransfer() public {
        _registrarTransferAssumptions(owner, owner, recipient, notaId);
        _registrarSafeTransferHelper(owner, owner, recipient, notaId, abi.encode(""));
    }

    function testSafeTransferWithData() public {
        bytes memory data = "test data";
        _registrarTransferAssumptions(owner, owner, recipient, notaId);
        _registrarSafeTransferHelper(owner, owner, recipient, notaId, data);
    }

    function testSafeTransferApproved() public {
        _registrarApproveHelper(owner, caller, notaId);
        _registrarSafeTransferHelper(caller, owner, recipient, notaId, abi.encode(""));
    }

    function testSafeTransferOperator() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721.ApprovalForAll(owner, caller, true);
        
        vm.prank(owner);
        REGISTRAR.setApprovalForAll(caller, true);
        _registrarSafeTransferHelper(caller, owner, recipient, notaId, abi.encode(""));
    }

    function testSafeTransferFailUnauthorized(address unauthorized) public {
        vm.assume(unauthorized != owner);
        vm.assume(unauthorized != REGISTRAR.getApproved(notaId));
        vm.assume(!REGISTRAR.isApprovedForAll(owner, unauthorized));

        vm.expectRevert("NOT_APPROVED_OR_OWNER");
        vm.prank(unauthorized);
        REGISTRAR.safeTransferFrom(owner, recipient, notaId);
    }

    function testSafeTransferFailToContract() public {
        MockERC20 contractAddr = new MockERC20("TEST", "TEST");
        
        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");
        vm.prank(owner);
        REGISTRAR.safeTransferFrom(owner, address(contractAddr), notaId);
    }

    function testFuzzSafeTransfer(address to, bytes calldata testData) public {
        bytes memory data;
        if (testData.length == 0){
            data = abi.encode("");
        } else {
            data = testData;
        }

        vm.assume(to != address(0));
        vm.assume(!_isContract(to));
        _registrarTransferAssumptions(owner, owner, to, notaId);
        _registrarSafeTransferHelper(owner, owner, to, notaId, data);
    }
}