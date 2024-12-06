// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract FundTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    uint256 escrowAmount = 1 ether;
    uint256 public notaId;

    function setUp() public override {
        super.setUp();
        
        _fundCallerApproveAddress(caller, DAI, escrowAmount, address(REGISTRAR));
        notaId = _registrarWriteHelper(caller, address(DAI), escrowAmount, 0, owner, HOOK, "");
    }

    function testFund(uint256 amount, uint256 instant) public {
        vm.assume(((amount >> 2) + (instant >> 2)) <= (type(uint256).max >> 2) - escrowAmount);

        _fundCallerApproveAddress(caller, DAI, amount + instant, address(REGISTRAR));
        _registrarFundHelper(caller, notaId, amount, instant, "");
    }


    function testFundWithHookFee() public {
        uint256 hookFee = 100;
        HOOK.setFee(hookFee);
        
        _fundCallerApproveAddress(caller, DAI, 1 ether + hookFee, address(REGISTRAR));
        _registrarFundHelper(caller, notaId, 1 ether, 0, "");
    }

    function testFundInvalidNota() public {
        uint256 invalidNotaId = 999;

        vm.expectRevert(INotaRegistrar.NonExistent.selector);
        REGISTRAR.fund(invalidNotaId, 1 ether, 0, "");
    }

    function testFailFundWithInsufficientBalance() public {
        uint256 amount = 100 ether;
        uint256 instant = 50 ether;
        
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        _registrarFundHelper(caller, notaId, amount, instant, "");
    }
}
