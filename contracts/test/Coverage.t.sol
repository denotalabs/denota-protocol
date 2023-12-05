// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {Coverage} from "../src/modules/Coverage.sol";
import {RegistrarTest} from "./Registrar.t.sol";


contract CoverageTest is Test, RegistrarTest {
    Coverage public COVERAGE;
    address liquidityProvider;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels
        
        liquidityProvider = address(1);

        COVERAGE = new Coverage(
            address(REGISTRAR),
            DataTypes.WTFCFees(0, 0, 0, 0),
            "ipfs://", 
            address(DAI),
            120 days,
            180 days,
            2_000
        );

        REGISTRAR.whitelistModule(
            address(COVERAGE),
            true,
            false,
            "Coverage"
        );
        vm.label(address(COVERAGE), "Coverage");
        vm.label(liquidityProvider, "LiquidityProvider");
    }


    function testDeposit(uint256 fundingAmount) public {
        vm.assume(fundingAmount <= tokensCreated);

        assertFalse(COVERAGE.fundingStarted());
        // Give LP tokens, LP gives COVERAGE token approval, deposit()
        _depositHelper(fundingAmount);

        // Ensure that reserve variables were updated
        assertEq(COVERAGE.totalReserves(), fundingAmount);
        assertEq(COVERAGE.availableReserves(), fundingAmount);
        assertTrue(COVERAGE.fundingStarted());
        assertEq(COVERAGE.balanceOf(liquidityProvider), fundingAmount);  // LP ERC20 was minted
    }
    
    function _depositHelper(uint256 fundingAmount) internal {
        // Give LP tokens
        DAI.transfer(liquidityProvider, fundingAmount);
        // Ensure LP has tokens
        assertEq(DAI.balanceOf(liquidityProvider), fundingAmount);
        
        vm.prank(liquidityProvider);
        DAI.approve(address(COVERAGE), fundingAmount);
        // Ensure approval
        assertEq(DAI.allowance(liquidityProvider, address(COVERAGE)), fundingAmount);

        vm.prank(liquidityProvider);
        COVERAGE.deposit(fundingAmount);
        // Ensure token balance was reduced
        assertEq(DAI.balanceOf(liquidityProvider), 0);
    }

    function testAddToWhitelist(address _address) public {
        // Not whitelisted test
        assertFalse(COVERAGE.isWhitelisted(_address), "Already whitelisted");

        // Whitelist
        COVERAGE.addToWhitelist(_address);

        // Whitelisted test
        assertTrue(COVERAGE.isWhitelisted(_address), "Not whitelisted");
    }

    function testRemoveFromWhitelist(address _address) public {
        testAddToWhitelist(_address);
        // Un-whitelist
        COVERAGE.removeFromWhitelist(_address);
        // Whitelisted test
        assertFalse(COVERAGE.isWhitelisted(_address), "Still whitelisted");
    }

    function testWrite(
        address caller,
        uint256 coverageAmount,
        uint256 escrowed,
        address coverageHolder
    ) public {
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        vm.assume((escrowed == 0) && (coverageAmount < tokensCreated));
        
        uint256 premium = (coverageAmount / 10_000) * 50;       
        _preWriteTokens(caller, DAI, escrowed, premium, COVERAGE);

        // Caller not whitelisted
        COVERAGE.addToWhitelist(caller); // Question: ensure whitelist?
        
        _depositHelper(coverageAmount);

        // Write Nota
        registrarWriteBefore(caller, coverageHolder);
        REGISTRAR.whitelistToken(address(DAI), true, "DAI");  // TODO where should this be? In a setup function?
        vm.prank(caller);
        uint256 cheqId = REGISTRAR.write(
            address(DAI),
            escrowed,
            premium, // instant
            address(COVERAGE),
            address(COVERAGE),
            abi.encode(
                coverageHolder, // coverageHolder
                coverageAmount, // coverageAmount
                50 // riskScore
            )
        ); 

        registrarWriteAfter(
            cheqId,
            address(DAI),
            escrowed,
            address(COVERAGE),
            address(COVERAGE)
        );
    }

    function claimCoverage(uint256 fundingAmount) public {
        // deposit
        _depositHelper(fundingAmount);
        // whitelist coverage writer

        // 

    }

    function getYield(uint256 notaId) public {  // TODO inefficient

    }

    function testWithdraw(uint256 fundingAmount) public {
        _depositHelper(fundingAmount);

    }
}
