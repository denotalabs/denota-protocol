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
        _tokenFundAddressApproveAddress(liquidityProvider, DAI, 0, fundingAmount, COVERAGE, address(COVERAGE));
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
            address(COVERAGE), // module
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
            assertEq(COVERAGE.reservesReleaseDate(), reservesReleaseDateBefore + COVERAGE.RESERVE_LOCKUP_PERIOD());
        }
        assertEq(yieldedFundsBefore, yieldedFundsBefore + instant);

        // Coverage struct
        assertLt(block.timestamp, COVERAGE.coverageInfoMaturityDate(notaId), "Nota Matured");
        assertFalse(COVERAGE.coverageInfoWasRedeemed(notaId), "Nota Already Redeemed");
        assertEq(coverageHolder, COVERAGE.coverageInfoCoverageHolder(notaId), "Incorrect Coverage Holder");
        assertEq(coverageAmount, COVERAGE.coverageInfoCoverageAmount(notaId), "Nota Already Redeemed");
        return notaId;
    }

    function testWrite(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
    ) public {
        // BUG having a coverageAmount of 1 allows the user to pay 0 in premium
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        vm.assume(coverageAmount < TOKENS_CREATED);
        vm.label(caller, "Caller");
        vm.label(coverageHolder, "Coverage Holder");

        // Give caller enough to pay for coverage and approve registrar to take from them
        _registrarModuleWhitelistHelper(address(COVERAGE), true, false, "Coverage");
        _registrarTokenWhitelistHelper(address(DAI));
        _addWhitelistHelper(caller);
        _tokenFundAddressApproveAddress(liquidityProvider, DAI, 0, coverageAmount, COVERAGE, address(COVERAGE));   // Should instant be `instant` or coverageAmount?
        _depositHelper(coverageAmount);

        uint256 instant = (coverageAmount / 10_000) * 50;
        _tokenFundAddressApproveAddress(caller, DAI, 0, instant, COVERAGE, address(REGISTRAR));  // Should instant be `instant` or coverageAmount?
        _writeHelper(caller, coverageAmount, instant, coverageHolder);
        }
    
    function _claimCoverageHelper(
        address caller,
        uint256 notaId
        ) internal {
        // TODO before tests
        vm.warp(COVERAGE.coverageInfoMaturityDate(notaId));
        vm.prank(caller);
        COVERAGE.claimCoverage(notaId);

        // TODO after tests
        // assertTrue(COVERAGE.coverageInfoWasRedeemed(notaId), "Nota Already Redeemed");
        // assertGe(block.timestamp, COVERAGE.coverageInfoMaturityDate(notaId), "Nota Matured");
        // assertEq(coverageHolder, COVERAGE.coverageInfoCoverageHolder(notaId), "Incorrect Coverage Holder");
        // assertEq(coverageAmount, COVERAGE.coverageInfoCoverageAmount(notaId), "Nota Already Redeemed");
        // assertEq(DAI.balanceOf(caller), coverageAmount, "Tokens Not Transferred");
    }

    function claimCoverage(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
    ) public {
        // BUG having a coverageAmount of 1 allows the user to pay 0 in premium
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        vm.assume(coverageAmount < TOKENS_CREATED);
        vm.label(caller, "Caller");
        vm.label(coverageHolder, "Coverage Holder");

        // Give caller enough to pay for coverage and approve registrar to take from them
        _registrarModuleWhitelistHelper(address(COVERAGE), true, false, "Coverage");
        _registrarTokenWhitelistHelper(address(DAI));
        _addWhitelistHelper(caller);
        _tokenFundAddressApproveAddress(liquidityProvider, DAI, 0, coverageAmount, COVERAGE, address(COVERAGE));   // Should instant be `instant` or coverageAmount?
        _depositHelper(coverageAmount);

        uint256 instant = (coverageAmount / 10_000) * 50;
        _tokenFundAddressApproveAddress(caller, DAI, 0, instant, COVERAGE, address(REGISTRAR));  // Should instant be `instant` or coverageAmount?
        uint256 notaId = _writeHelper(caller, coverageAmount, instant, coverageHolder);
        
        _claimCoverageHelper(caller, notaId);
    }

    function _getYieldHelper(uint256 notaId) internal {
        /**
        require(!coverage.wasRedeemed);
        require(coverage.maturityDate <= block.timestamp);
        
        availableReserves += coverage.coverageAmount;
        */
    }

    function getYield(
        address caller,
        uint256 coverageAmount,
        address coverageHolder
        ) public {
        // BUG having a coverageAmount of 1 allows the user to pay 0 in premium
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        vm.assume(coverageAmount < TOKENS_CREATED);
        vm.label(caller, "Caller");
        vm.label(coverageHolder, "Coverage Holder");

        // Give caller enough to pay for coverage and approve registrar to take from them
        _registrarModuleWhitelistHelper(address(COVERAGE), true, false, "Coverage");
        _registrarTokenWhitelistHelper(address(DAI));
        _addWhitelistHelper(caller);
        _tokenFundAddressApproveAddress(liquidityProvider, DAI, 0, coverageAmount, COVERAGE, address(COVERAGE));   // Should instant be `instant` or coverageAmount?
        _depositHelper(coverageAmount);

        uint256 instant = (coverageAmount / 10_000) * 50;
        _tokenFundAddressApproveAddress(caller, DAI, 0, instant, COVERAGE, address(REGISTRAR));  // Should instant be `instant` or coverageAmount?
        uint256 notaId = _writeHelper(caller, coverageAmount, instant, coverageHolder);

        _getYieldHelper(notaId);
    }

    function _withdrawHelper(
        address caller
    ) internal {
        // TODO Before tests

        vm.prank(caller);
        COVERAGE.withdraw();

        // TODO After tests

        // withdrawal logic
        /**
        require(reservesReleaseDate >= block.timestamp);
        uint256 liquidityClaim = balanceOf(_msgSender());
        uint256 claimPercentage = liquidityClaim / totalReserves;
        uint256 yieldClaim = yieldedFunds * claimPercentage;

        _burn(_msgSender(), liquidityClaim);

        if (totalSupply() == 0){
            fundingStarted = false;
            poolStart = 0;
            reservesReleaseDate = 0;
            availableReserves = 0;
            yieldedFunds = 0;
        }
        
        IERC20(USDC).safeTransfer(_msgSender(), liquidityClaim + yieldClaim);
         */
    }

    function testWithdraw(address caller,
        uint256 coverageAmount,
        address coverageHolder
    ) public {
        // BUG having a coverageAmount of 1 allows the user to pay 0 in premium
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        vm.assume(coverageAmount < TOKENS_CREATED);
        vm.label(caller, "Caller");
        vm.label(coverageHolder, "Coverage Holder");

        // Give caller enough to pay for coverage and approve registrar to take from them
        _registrarModuleWhitelistHelper(address(COVERAGE), true, false, "Coverage");
        _registrarTokenWhitelistHelper(address(DAI));
        _addWhitelistHelper(caller);
        _tokenFundAddressApproveAddress(liquidityProvider, DAI, 0, coverageAmount, COVERAGE, address(COVERAGE));   // Should instant be `instant` or coverageAmount?
        _depositHelper(coverageAmount);

        uint256 instant = (coverageAmount / 10_000) * 50;
        _tokenFundAddressApproveAddress(caller, DAI, 0, instant, COVERAGE, address(REGISTRAR));  // Should instant be `instant` or coverageAmount?
        uint256 notaId = _writeHelper(caller, coverageAmount, instant, coverageHolder);
        _getYieldHelper(notaId);

        _withdrawHelper(caller);
    }
}
