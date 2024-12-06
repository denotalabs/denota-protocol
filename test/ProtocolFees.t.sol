// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract ProtocolFeesTest is BaseRegistrarTest {
    function setUp() public override {
        super.setUp();
    }

    function testSetProtocolFee() public {
        uint256 newFee = 100;
        
        REGISTRAR.setProtocolFee(newFee);
        assertEq(REGISTRAR.protocolFee(), newFee, "Protocol fee should be updated");
    }

    function testSetProtocolFeeByNonOwner() public {
        uint256 newFee = 100;
        address nonOwner = address(0xbeef);
        
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        REGISTRAR.setProtocolFee(newFee);
    }
}
