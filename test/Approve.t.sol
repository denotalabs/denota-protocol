// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract ApproveTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    address public spender = address(0xcafe);
    uint256 public notaId;

    function setUp() public override {
        super.setUp();
        
        _fundCallerApproveAddress(caller, DAI, 100, address(REGISTRAR));
        notaId = _registrarWriteHelper(caller, address(DAI), 100, 0, owner, HOOK, "");
    }

    function testApprove() public {
        vm.prank(owner);
        _registrarApproveHelper(owner, spender, notaId);
    }

    function testApproveUnauthorized(address unauthorized) public {
        vm.assume(unauthorized != owner);
        vm.assume(unauthorized != address(0));
        
        vm.expectRevert("ERC721: approve caller is not token owner or approved for all");
        vm.prank(unauthorized);
        REGISTRAR.approve(spender, notaId);
    }

    function testApproveAll() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721.ApprovalForAll(owner, spender, true);

        vm.prank(owner);
        REGISTRAR.setApprovalForAll(spender, true);
        
        assertTrue(REGISTRAR.isApprovedForAll(owner, spender));
    }

    function testApproveNonexistentToken(uint256 invalidNotaId) public {
        vm.assume(invalidNotaId >= REGISTRAR.nextId());
        
        vm.expectRevert(INotaRegistrar.NonExistent.selector);
        REGISTRAR.approve(spender, invalidNotaId);
    }
}
