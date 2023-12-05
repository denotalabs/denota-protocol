// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mock/erc20.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {INotaModule} from "../src/interfaces/INotaModule.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";

contract RegistrarTest is Test {
    NotaRegistrar public REGISTRAR;
    TestERC20 public DAI;
    TestERC20 public USDC;
    uint256 public immutable tokensCreated = 1_000_000_000_000e18;

    function isContract(address _addr) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setUp() public virtual {
        REGISTRAR = new NotaRegistrar(); 
        DAI = new TestERC20(tokensCreated, "DAI", "DAI"); 
        USDC = new TestERC20(0, "USDC", "USDC");

        vm.label(msg.sender, "Alice");
        vm.label(address(this), "TestingContract");
        vm.label(address(DAI), "TestDai");
        vm.label(address(USDC), "TestUSDC");
        vm.label(address(REGISTRAR), "NotaRegistrarContract");
    }

    function whitelist(address module, string calldata moduleName) public {
        // Whitelists tokens, rules, modules
        REGISTRAR.whitelistModule(module, false, true, moduleName); // Whitelist bytecode
    }

    function testWhitelistToken() public {
        address DAIAddress = address(DAI);
        vm.prank(address(this));

        // Whitelist tokens
        assertFalse(
            REGISTRAR.tokenWhitelisted(DAIAddress),
            "Unauthorized whitelist"
        );

        REGISTRAR.whitelistToken(DAIAddress, true, "DAI");
        
        assertTrue(
            REGISTRAR.tokenWhitelisted(DAIAddress),
            "Whitelisting failed"
        );
        
        REGISTRAR.whitelistToken(DAIAddress, false, "DAI");
        
        assertFalse(
            REGISTRAR.tokenWhitelisted(DAIAddress),
            "Un-whitelisting failed"
        );
    }

    function safeFeeMult(
        uint256 fee,
        uint256 amount
    ) public pure returns (uint256) {
        if (fee == 0) return 0;
        return (amount * fee) / 10_000;
    }

    function calcTotalFees(
        INotaModule module,
        uint256 escrowed,
        uint256 instant
    ) public view returns (uint256) {
        DataTypes.WTFCFees memory fees = module.getFees(address(0));
        uint256 totalTransfer = instant + escrowed;
        
        uint256 moduleFee = safeFeeMult(fees.writeBPS, totalTransfer);
        console.log("Module Fee: ", moduleFee);
        uint256 totalWithFees = totalTransfer + moduleFee;
        console.log(escrowed, "-->", totalWithFees);
        return totalWithFees;
    }

    function _preWriteTokens(address caller, TestERC20 token, uint256 escrowed, uint256 instant, INotaModule module) internal {
        uint256 totalWithFees = calcTotalFees(
            module,
            escrowed,
            instant
        );
        
        vm.prank(caller);
        token.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
        token.transfer(caller, totalWithFees);
        vm.assume(token.balanceOf(caller) >= totalWithFees);
    }

    function registrarWriteBefore(address caller, address recipient) public {
        assertEq(
            REGISTRAR.balanceOf(caller), 0,
            "Caller already had a cheq"
        );
        assertEq(
            REGISTRAR.balanceOf(recipient), 0,
            "Recipient already had a cheq"
        );
        assertEq(REGISTRAR.totalSupply(), 0, "Nota supply non-zero");
    }
    
    function registrarWriteAfter(
        uint256 cheqId,
        address currency,
        uint256 escrowed,
        address owner,
        address module
    ) public {
        assertEq(
            REGISTRAR.totalSupply(), 1,
            "Nota supply didn't increment"
        );

        assertEq(
            REGISTRAR.balanceOf(owner), 1,
            "Owner balance didn't increment"
        );

        assertEq(
            REGISTRAR.ownerOf(cheqId), owner,
            "`owner` isn't owner of cheq"
        );

        assertEq(
            REGISTRAR.cheqCurrency(cheqId), currency,
            "Incorrect token"
        );

        assertEq(
            REGISTRAR.cheqEscrowed(cheqId), escrowed,
            "Incorrect escrow"
        );

        assertEq(
            address(REGISTRAR.cheqModule(cheqId)), module,
            "Incorrect module"
        );
    }
}
