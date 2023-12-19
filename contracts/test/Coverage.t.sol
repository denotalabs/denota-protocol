// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota, WTFCFees} from "../src/libraries/DataTypes.sol";
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
            WTFCFees(0, 0, 0, 0),
            "ipfs://", 
            address(DAI),
            120 days,
            180 days,
            2_000
        );

        vm.label(address(COVERAGE), "Coverage");
        vm.label(liquidityProvider, "LiquidityProvider");
    }

    // Helper functions do a single beforeFunction, callFunction, afterFunction state change. testX functions must call them in sequence
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
        // TODO include more preDeposit assertions
        assertFalse(COVERAGE.fundingStarted());
        vm.prank(liquidityProvider);
        COVERAGE.deposit(fundingAmount);

        // Ensure token balance was reduced
        assertEq(DAI.balanceOf(liquidityProvider), 0);
        assertTrue(COVERAGE.fundingStarted());
        // Ensure that reserve variables were updated
        assertEq(COVERAGE.totalReserves(), fundingAmount);
        assertEq(COVERAGE.availableReserves(), fundingAmount);
        assertEq(COVERAGE.balanceOf(liquidityProvider), fundingAmount);  // LP ERC20 was minted
    
    }

    function testDeposit(uint256 fundingAmount) public {
        vm.assume(fundingAmount <= TOKENS_CREATED);
        // Give LP tokens, LP gives COVERAGE token approval
        _tokenFundAddressApproveAddress(liquidityProvider, DAI, fundingAmount, address(COVERAGE));
        _depositHelper(fundingAmount);
    }

    function _writeHelper(
        address caller,
        uint256 coverageAmount,
        uint256 instant,
        address coverageHolder
    ) internal returns (uint256){
        uint256 notaIdNext = REGISTRAR.totalSupply();
        // Reserve state variables before write
        uint256 availableReservesBefore = COVERAGE.availableReserves();
        uint256 poolStartBefore = COVERAGE.poolStart();
        uint256 reservesReleaseDateBefore = COVERAGE.reservesReleaseDate();
        uint256 yieldedFundsBefore = COVERAGE.yieldedFunds();
        // Nota state before write
        assertEq(address(0), COVERAGE.coverageInfoCoverageHolder(notaIdNext), "Pre-set Coverage Holder");
        assertEq(0, COVERAGE.coverageInfoMaturityDate(notaIdNext), "Pre-set Maturity Date");
        assertEq(0, COVERAGE.coverageInfoCoverageAmount(notaIdNext), "Pre-set Coverage Amount");
        assertFalse(COVERAGE.coverageInfoWasRedeemed(notaIdNext), "Pre-set Redeem");

        uint256 notaId = _registrarWriteHelper(
            caller, // caller
            address(DAI), // currency
            0, // escrowed
            instant, // instant (premium)
            address(COVERAGE), // owner
            COVERAGE, // module
            abi.encode(  // moduleData
                coverageHolder,
                coverageAmount,
                50
            )
        );
        assertEq(notaId, notaIdNext, "Increment failed");

        // Compare after write states to before write
        uint256 scaledCoverageAmount = (coverageAmount * COVERAGE.MAX_RESERVE_BPS()) / 10_000;
        assertEq(COVERAGE.availableReserves(), availableReservesBefore - scaledCoverageAmount);
        
        if (poolStartBefore == 0){
            assertEq(COVERAGE.poolStart(), block.timestamp);  // TODO will this always hold?
            assertEq(COVERAGE.reservesReleaseDate(), reservesReleaseDateBefore + block.timestamp + COVERAGE.RESERVE_LOCKUP_PERIOD()); // TODO will adding by block.timestamp always hold?
        }
        assertEq(COVERAGE.yieldedFunds(), yieldedFundsBefore + instant);

        // Coverage struct
        assertLt(block.timestamp, COVERAGE.coverageInfoMaturityDate(notaId), "Nota Matured");
        assertFalse(COVERAGE.coverageInfoWasRedeemed(notaId), "Nota Already Redeemed");
        assertEq(coverageHolder, COVERAGE.coverageInfoCoverageHolder(notaId), "Incorrect Coverage Holder");
        assertEq(coverageAmount, COVERAGE.coverageInfoCoverageAmount(notaId), "Nota Already Redeemed");
        return notaId;
    }

    function _writeCoverageAssumptions(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
    ) internal returns(uint256){
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        uint256 premium = (coverageAmount / 10_000) * 50;
        vm.assume(((coverageAmount / 2 + premium / 2) < TOKENS_CREATED / 2) && premium !=0);  // TODO does adding premium!=0 solve 1 wei coverage => 0 premium?

        vm.label(caller, "Caller");
        vm.label(coverageHolder, "Coverage Holder");
        return premium;
    }

    function _setupThenWrite(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
    ) internal returns(uint256 notaId){
        uint256 premium = _writeCoverageAssumptions(caller, coverageAmount, coverageHolder);

        _registrarModuleWhitelistToggleHelper(COVERAGE, false);
        _registrarTokenWhitelistToggleHelper(address(DAI), false);
        _addWhitelistHelper(caller);
        _tokenFundAddressApproveAddress(liquidityProvider, DAI, coverageAmount, address(COVERAGE));
        _depositHelper(coverageAmount);

        _tokenFundAddressApproveAddress(caller, DAI, premium, address(REGISTRAR));
        notaId = _writeHelper(caller, coverageAmount, premium, coverageHolder);
    }

    function testWrite(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
    ) public {
        _setupThenWrite(caller, coverageAmount, coverageHolder);
    }
    
    function _claimCoverageHelper(
        uint256 notaId
        ) internal {
        // Nota state before write
        address coverageHolderBefore = COVERAGE.coverageInfoCoverageHolder(notaId);
        uint256 maturityDateBefore = COVERAGE.coverageInfoMaturityDate(notaId);
        uint256 coverageAmountBefore = COVERAGE.coverageInfoCoverageAmount(notaId);
        bool wasRedeemedBefore = COVERAGE.coverageInfoWasRedeemed(notaId);
        uint256 coverageHolderTokensBefore = DAI.balanceOf(coverageHolderBefore);

        assertNotEq(address(0), coverageHolderBefore, "Uninitialized Coverage Holder");
        assertNotEq(0, maturityDateBefore, "Uninitialized Maturity Date");
        assertNotEq(0, coverageAmountBefore, "Uninitialized Coverage Amount");
        assertFalse(wasRedeemedBefore, "Already Claimed");
        // TODO how to test maturity date and coverage holder conditions

        vm.prank(coverageHolderBefore);
        COVERAGE.claimCoverage(notaId);
        
        assertTrue(COVERAGE.coverageInfoWasRedeemed(notaId), "Nota Not Redeemed");
        assertEq(coverageHolderBefore, COVERAGE.coverageInfoCoverageHolder(notaId), "Incorrect Coverage Holder");
        assertEq(maturityDateBefore, COVERAGE.coverageInfoMaturityDate(notaId), "Nota Matured");
        assertEq(coverageAmountBefore, COVERAGE.coverageInfoCoverageAmount(notaId), "Nota Already Redeemed");
        assertEq(DAI.balanceOf(coverageHolderBefore), coverageHolderTokensBefore + coverageAmountBefore, "Tokens Not Transferred");
    }

    function testClaimCoverage(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
    ) public {
        uint256 notaId = _setupThenWrite(caller, coverageAmount, coverageHolder);
        _claimCoverageHelper(notaId);
    }

    function _getYieldHelper(uint256 notaId) internal {
        assertLt(block.timestamp, COVERAGE.coverageInfoMaturityDate(notaId), "Already matured");
        assertFalse(COVERAGE.coverageInfoWasRedeemed(notaId), "Already redeemed");
        uint256 availableReservesBefore = COVERAGE.availableReserves();
        uint256 maturityDate = COVERAGE.coverageInfoMaturityDate(notaId);

        vm.warp(maturityDate);
        COVERAGE.getYield(notaId);

        assertEq(COVERAGE.availableReserves(), availableReservesBefore + COVERAGE.coverageInfoCoverageAmount(notaId));
        assertTrue(COVERAGE.coverageInfoWasRedeemed(notaId), "Not redeemed");
    }

    function testGetYield(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
        ) public {
        uint256 notaId = _setupThenWrite(caller, coverageAmount, coverageHolder);

        _getYieldHelper(notaId);
    }

    function _withdrawHelper(
    ) internal {
        uint256 liquidityDepositedBefore = COVERAGE.balanceOf(liquidityProvider);
        uint256 claimPercentage = liquidityDepositedBefore / COVERAGE.totalReserves();
        uint256 yieldClaim = COVERAGE.yieldedFunds() * claimPercentage;
        assertGe(COVERAGE.reservesReleaseDate(), block.timestamp);
        uint256 daiBalanceBefore = DAI.balanceOf(liquidityProvider);
        uint256 totalSupplyBefore = COVERAGE.totalSupply();

        vm.prank(liquidityProvider);
        COVERAGE.withdraw();

        if (COVERAGE.totalSupply() == 0){
            assertFalse(COVERAGE.fundingStarted());
            assertEq(COVERAGE.poolStart(), 0);
            assertEq(COVERAGE.reservesReleaseDate(), 0);
            assertEq(COVERAGE.availableReserves(), 0);
            assertEq(COVERAGE.yieldedFunds(), 0);
        }

        assertEq(totalSupplyBefore - liquidityDepositedBefore, COVERAGE.totalSupply());
        assertEq(COVERAGE.balanceOf(liquidityProvider), 0);

        assertEq(daiBalanceBefore + liquidityDepositedBefore + yieldClaim, DAI.balanceOf(liquidityProvider)); 
    }

    function testWithdraw(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
    ) public {
        uint256 notaId = _setupThenWrite(caller, coverageAmount, coverageHolder);
        _getYieldHelper(notaId);

        _withdrawHelper();
    }
}
