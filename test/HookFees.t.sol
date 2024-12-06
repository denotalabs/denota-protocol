// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract HookFeesTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    uint256 public notaId;

    function setUp() public override {
        super.setUp();
        
        _fundCallerApproveAddress(caller, DAI, 100 ether, address(REGISTRAR));
        notaId = _registrarWriteHelper(caller, address(DAI), 1 ether, 0, owner, HOOK, "");
    }

    function testSetHookFee() public {
        uint256 newFee = 100;
        
        HOOK.setFee(newFee);
        assertEq(HOOK.fee(), newFee, "Hook fee should be updated");
    }

    function testFailSetHookFeeByNonOwner() public {
        uint256 newFee = 100;
        address nonOwner = address(0xbeef);
        
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        HOOK.setFee(newFee);
    }
}
