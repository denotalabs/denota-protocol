// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract WriteTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);

    function setUp() public override {
        super.setUp();
    }

    function testWrite(uint256 escrowed, uint256 instant) public {
        _registrarWriteAssumptions(caller, escrowed, instant, owner);

        _fundCallerApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));

        _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, HOOK, "");
    }

    function testWriteFailInsufficientBalance() public {
        vm.expectRevert("ERC20: insufficient allowance");
        REGISTRAR.write(address(DAI), 1 ether, 1 ether, owner, HOOK, "");
    }

    function testWriteWithZeroEscrowed() public {
        uint256 instant = 100;
        _fundCallerApproveAddress(caller, DAI, instant, address(REGISTRAR));

        _registrarWriteHelper(caller, address(DAI), 0, instant, owner, HOOK, "");
    }

    function testWriteEscrowedWithMaxValue() public {
        uint256 maxValue = type(uint256).max;
        _fundCallerApproveAddress(caller, DAI, maxValue, address(REGISTRAR));

        vm.prank(caller);
        REGISTRAR.write(address(DAI), maxValue, 0, owner, HOOK, "");
    }

    function testWriteToZeroAddress() public {
        _fundCallerApproveAddress(caller, DAI, 1 ether, address(REGISTRAR));

        vm.expectRevert("ERC721: mint to the zero address");
        vm.prank(caller);
        REGISTRAR.write(address(DAI), 1 ether, 0, address(0), HOOK, "");
    }

    function testWriteInstantToZeroAddress() public {
        _fundCallerApproveAddress(caller, DAI, 1 ether, address(REGISTRAR));

        vm.expectRevert("ERC20: transfer to the zero address");
        vm.prank(caller);
        REGISTRAR.write(address(DAI), 0, 1 ether, address(0), HOOK, "");
    }

    function testWriteWithInsufficientAllowance() public {
        uint256 escrowed = 100;
        uint256 instant = 50;
        _fundCallerApproveAddress(caller, DAI, escrowed + instant - 1, address(REGISTRAR));

        vm.expectRevert("ERC20: insufficient allowance");
        REGISTRAR.write(address(DAI), escrowed, instant, owner, HOOK, "");
    }

    function testWriteIncrementsNextId() public {
        uint256 initialNextId = REGISTRAR.nextId();
        _fundCallerApproveAddress(caller, DAI, 150, address(REGISTRAR));

        _registrarWriteHelper(caller, address(DAI), 100, 50, owner, HOOK, "");

        assertEq(REGISTRAR.nextId(), initialNextId + 1, "NextId should increment after write");
    }

    function testWriteInstantWithMaxValue() public {
        uint256 maxValue = type(uint256).max;
        _fundCallerApproveAddress(caller, DAI, maxValue, address(REGISTRAR));

        vm.expectRevert("ERC20: insufficient allowance");
        REGISTRAR.write(address(DAI), 0, maxValue, owner, HOOK, "");
    }

    function testWriteWithZeroInstant() public {
        uint256 escrowed = 100;
        _fundCallerApproveAddress(caller, DAI, escrowed, address(REGISTRAR));
        _registrarWriteHelper(caller, address(DAI), escrowed, 0, owner, HOOK, "");
        assertEq(DAI.balanceOf(owner), 0, "Owner should not receive any instant amount");
    }

    function testWriteWithCustomHookData() public {
        bytes memory customHookData = abi.encode("Custom data");
        _fundCallerApproveAddress(caller, DAI, 150, address(REGISTRAR));
        _registrarWriteHelper(caller, address(DAI), 100, 50, owner, HOOK, customHookData);
    }

    function testWriteWithHookFee(uint256 escrowed, uint256 instant) public {
        uint256 hookFee = 100;
        vm.assume(((escrowed >> 2) + hookFee) <= type(uint256).max >> 2);
        HOOK.setFee(hookFee);

        _registrarWriteAssumptions(caller, escrowed + hookFee, instant, owner);

        _fundCallerApproveAddress(caller, DAI, escrowed + hookFee + instant, address(REGISTRAR));

        _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, HOOK, "");
    }

    function testWriteZeroEscrowWithHookFee(uint256 instant) public {
        // Performs transferFrom of escrowed + hookFee (so just fee)
        uint256 hookFee = 100;
        HOOK.setFee(hookFee);

        _registrarWriteAssumptions(caller, hookFee, instant, owner);

        _fundCallerApproveAddress(caller, DAI, hookFee + instant, address(REGISTRAR));

        _registrarWriteHelper(caller, address(DAI), 0, instant, owner, HOOK, "");
    }

    function testFuzzWrite(uint256 escrowed, uint256 instant) public {
        _registrarWriteAssumptions(caller, escrowed, instant, owner);
        _fundCallerApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));

        _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, HOOK, "");
    }
}
