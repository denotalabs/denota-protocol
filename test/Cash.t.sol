// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./BaseRegistrarTest.t.sol";

contract CashTest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    address public to = address(0xcafe);
    uint256 public notaId;

    function setUp() public override {
        super.setUp();
        
        _fundCallerApproveAddress(caller, DAI, 100 ether, address(REGISTRAR));
        notaId = _registrarWriteHelper(caller, address(DAI), 1 ether, 0, owner, HOOK, "");
    }

    function testCash() public {
        uint256 amount = 1 ether;
        
        _fundCallerApproveAddress(caller, DAI, amount, address(REGISTRAR));
        _registrarFundHelper(caller, notaId, amount, 0, "");
        
        uint256 initialBalance = DAI.balanceOf(to);
        REGISTRAR.cash(notaId, amount, to, "");
        uint256 finalBalance = DAI.balanceOf(to);
        
        assertEq(finalBalance, initialBalance + amount, "Caller should receive the cashed out amount");
    }

    function testFuzzCash(uint256 amount) public {
        // Bound amount to reasonable values
        amount = bound(amount, 0.0001 ether, 99 ether);
        
        _fundCallerApproveAddress(caller, DAI, amount, address(REGISTRAR));
        _registrarFundHelper(caller, notaId, amount, 0, "");
        
        uint256 initialBalance = DAI.balanceOf(to);
        REGISTRAR.cash(notaId, amount, to, "");
        uint256 finalBalance = DAI.balanceOf(to);
        
        assertEq(finalBalance, initialBalance + amount, "Cashed amount not received correctly");
    }


    function testFailCashByNonOwner() public {
        uint256 amount = 1 ether;
        address nonOwner = address(0xbeef);
        
        vm.prank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        REGISTRAR.cash(notaId, amount, to, "");
    }

    function testCashInvalidNota() public {
        uint256 amount = 1 ether;
        uint256 invalidNotaId = 999;
        
        vm.expectRevert(INotaRegistrar.NonExistent.selector);
        REGISTRAR.cash(invalidNotaId, amount, to, "");
    }
}
