// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {Coverage} from "../src/modules/Coverage.sol";
import {RegistrarTest} from "./Registrar.t.sol";

// TODO Invariant test certain properties: ie coverageHolder, maturityDate, etc
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

        vm.label(address(COVERAGE), "Coverage");
        vm.label(liquidityProvider, "LiquidityProvider");
    }

    function _addWhitelistHelper(address _address) internal {
        // Not whitelisted test
        assertFalse(COVERAGE.isWhitelisted(_address), "Already whitelisted");

        // Whitelist
        COVERAGE.addToWhitelist(_address);

        // Whitelisted test
        assertTrue(COVERAGE.isWhitelisted(_address), "Not whitelisted");
    }
    function testAddToWhitelist(address _address) public {
        _addWhitelistHelper(_address);
    }

    function testRemoveFromWhitelist(address _address) public {
        _addWhitelistHelper(_address);
        // Un-whitelist
        COVERAGE.removeFromWhitelist(_address);
        // Whitelisted test
        assertFalse(COVERAGE.isWhitelisted(_address), "Still whitelisted");
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

    function testDeposit(uint256 fundingAmount) public {
        vm.assume(fundingAmount <= TOKENS_CREATED);

        assertFalse(COVERAGE.fundingStarted());
        // Give LP tokens, LP gives COVERAGE token approval, deposit()
        _depositHelper(fundingAmount);

        // Ensure that reserve variables were updated
        assertEq(COVERAGE.totalReserves(), fundingAmount);
        assertEq(COVERAGE.availableReserves(), fundingAmount);
        assertTrue(COVERAGE.fundingStarted());
        assertEq(COVERAGE.balanceOf(liquidityProvider), fundingAmount);  // LP ERC20 was minted
    }

    function testWrite(
        address caller,
        uint256 coverageAmount,
        uint256 escrowed,
        address coverageHolder
    ) public {
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        vm.assume((escrowed == 0) && (coverageAmount < TOKENS_CREATED));
        
        uint256 instant = (coverageAmount / 10_000) * 50;
        _fundCallerApproveRegistrar(caller, DAI, escrowed, instant, COVERAGE);
        _registrarModuleWhitelistHelper(address(COVERAGE), true, false, "Coverage");
        _registrarTokenWhitelistHelper(address(DAI));
        _addWhitelistHelper(caller);
        _depositHelper(coverageAmount);
        
        _writeHelper(
            caller, // caller
            address(DAI), // currency
            escrowed, // escrowed
            instant, // instant (premium)
            address(COVERAGE), // owner
            address(COVERAGE), // module
            abi.encode(  // moduleData
                coverageHolder, 
                coverageAmount, 
                50
            )
        );
    }
    
    function claimCoverage(
        address caller,
        uint256 coverageAmount,
        uint256 escrowed,
        address coverageHolder
    ) public {
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        vm.assume((escrowed == 0) && (coverageAmount < TOKENS_CREATED));
        vm.label(caller, "CoverageRequester");
        vm.label(coverageHolder, "CoverageHolder");
        
        uint256 instant = (coverageAmount / 10_000) * 50;

        _fundCallerApproveRegistrar(caller, DAI, escrowed, instant, COVERAGE);
        _addWhitelistHelper(caller);
        _depositHelper(coverageAmount);
        _registrarModuleWhitelistHelper(address(COVERAGE), true, false, "Coverage");
        _registrarTokenWhitelistHelper(address(DAI));
        
        uint256 notaId = _writeHelper(
            caller, // caller
            address(DAI), // currency
            escrowed, // escrowed
            instant, // instant (premium)
            address(COVERAGE), // owner
            address(COVERAGE), // module
            abi.encode(  // moduleData
                coverageHolder, 
                coverageAmount, 
                50
            )
        );

        assertFalse(COVERAGE.coverageInfoWasRedeemed(notaId), "Nota Already Redeemed");
        assertLt(block.timestamp, COVERAGE.coverageInfoMaturityDate(notaId), "Nota Matured");
        assertEq(coverageHolder, COVERAGE.coverageInfoCoverageHolder(notaId), "Incorrect Coverage Holder");
        assertEq(coverageAmount, COVERAGE.coverageInfoCoverageAmount(notaId), "Nota Already Redeemed");
        assertEq(DAI.balanceOf(caller), 0, "Tokens Not Transferred");
        
        vm.warp(COVERAGE.coverageInfoMaturityDate(notaId));
        COVERAGE.claimCoverage(notaId);

        assertTrue(COVERAGE.coverageInfoWasRedeemed(notaId), "Nota Already Redeemed");
        assertGe(block.timestamp, COVERAGE.coverageInfoMaturityDate(notaId), "Nota Matured");
        assertEq(coverageHolder, COVERAGE.coverageInfoCoverageHolder(notaId), "Incorrect Coverage Holder");
        assertEq(coverageAmount, COVERAGE.coverageInfoCoverageAmount(notaId), "Nota Already Redeemed");
        assertEq(DAI.balanceOf(caller), coverageAmount, "Tokens Not Transferred");
    }

    // function getYield(uint256 notaId) public {  // TODO inefficient

    // }

    // function testWithdraw(uint256 fundingAmount) public {
    //     _depositHelper(fundingAmount);

    // }
}
