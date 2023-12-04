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
        
        REGISTRAR.whitelistToken(address(DAI), true, "DAI");
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

        vm.prank(liquidityProvider);
        DAI.approve(address(COVERAGE), fundingAmount);
        // Ensure approval
        assertTrue(DAI.allowance(liquidityProvider, address(COVERAGE)) == fundingAmount);
        // Give LP tokens
        DAI.transfer(liquidityProvider, fundingAmount);
        // Ensure LP has tokens
        assertTrue(DAI.balanceOf(liquidityProvider) == fundingAmount);

        assertFalse(COVERAGE.fundingStarted());
        vm.prank(liquidityProvider);
        COVERAGE.deposit(fundingAmount);
        // Ensure token balance was reduced
        assertTrue(DAI.balanceOf(liquidityProvider) == 0);

        assertTrue(COVERAGE.totalReserves() == fundingAmount);
        assertTrue(COVERAGE.availableReserves() == fundingAmount);
        assertTrue(COVERAGE.fundingStarted());
        assertTrue(COVERAGE.balanceOf(liquidityProvider) == fundingAmount);  // ERC20 was minted

    }
    
    function testWithdraw(uint256 fundingAmount) public {
    }

    function testWrite(
        address caller,
        uint256 coverageAmount,
        uint256 escrowed,
        uint256 instant,
        address coverageHolder
    ) public {
        vm.assume(caller != address(0) && caller != liquidityProvider && caller != coverageHolder && coverageHolder != address(0) && coverageAmount != 0);
        vm.assume((escrowed < tokensCreated) && (instant < tokensCreated));
        _preWriteTokens(caller, DAI, escrowed, instant, COVERAGE);
        registrarWriteBefore(caller, coverageHolder);

        // Caller not whitelisted
        COVERAGE.addToWhitelist(caller);
        // ensure whitlisted

        // instant value
        instant = (coverageAmount / 10_000) * 50;
        console.log(instant);

        vm.prank(caller);
        uint256 cheqId = REGISTRAR.write(
            address(DAI),
            escrowed,
            instant,
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

        // INotaModule wrote correctly to it's storage
        string memory tokenURI = REGISTRAR.tokenURI(cheqId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }
    function testAddToWhitelist() public {
        // function addToWhitelist(address _address) external onlyOwner {
    }

    function testRemoveFromWhitelist() public {
        // function removeFromWhitelist(address _address) external onlyOwner {
    }
}
