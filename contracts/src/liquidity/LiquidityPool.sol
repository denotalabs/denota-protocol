// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {CheqRegistrar} from "../CheqRegistrar.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Coverage} from "../modules/Coverage.sol";

contract LiquidityPool {
    using SafeERC20 for IERC20;

    CheqRegistrar public registrar;
    address public coverageModule;
    address public usdc;

    constructor(
        CheqRegistrar _registrar,
        address _coverageModule,
        address _usdc
    ) {
        registrar = _registrar;
        coverageModule = _coverageModule;
        usdc = _usdc;
    }

    function fundPool(uint256 fundingAmount) public {
        // Liquidity providers deposit tokens (USDC) to fund the pool
        IERC20(usdc).safeTransfer(address(this), fundingAmount);

        // LPs receive pool tokens in return
        // TODO: figure out token issuance and redemption
    }

    function mintNota(
        uint256 riskScore, // represented in basis points
        uint256 coverageAmount
    ) public payable returns (uint256) {
        // TODO: only allow trusted addresses to call this

        uint256 riskFee = (coverageAmount / 10000) * riskScore;

        // Custom module stores metadata
        bytes memory modulePayload = abi.encode(msg.sender, coverageAmount);

        // Mint nota, direct pay risk fee into liquidity pool
        // Maybe onramp should hold the nota? (represents an asset for the onramp, a liability for the pool)
        uint256 notaId = registrar.write(
            usdc,
            0,
            riskFee,
            address(this),
            coverageModule,
            modulePayload
        );

        return notaId;
    }

    function recoverFunds(uint256 notaId) public {
        Coverage coverage = Coverage(coverageModule);

        (
            address coverageHolder,
            uint256 coverageAmount,
            bool wasRedeemed
        ) = coverage.payInfo(notaId);

        require(!wasRedeemed);
        require(msg.sender == coverageHolder);

        // MVP: just send funds to the holder (doesn't scale but makes the demo easier)
        IERC20(usdc).safeTransfer(coverageHolder, coverageAmount);

        // Update nota state to "redeemed"
        coverage.recoverFunds(notaId);
    }
}
