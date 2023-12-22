// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/console.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

// Assumes: a single LP, a single liquidity deposit, a single lockup period (with endDate buffer=endDate  - coverage maturity), coverage is fully backed
// TODO add reserve pool specific events
// TODO add custom errors
contract Coverage is Ownable, ModuleBase, ERC20 {
    using SafeERC20 for IERC20;

    uint256 immutable public RESERVE_LOCKUP_PERIOD;  // LP locks for 6 months
    uint256 immutable public COVERAGE_PERIOD;  // Nota coverage period
    uint256 immutable public MAX_RESERVE_BPS;  // MAX_RESERVE_BPS/10_000 = x% (2_000 = 20% => 1$ reserved : 5$ covered)
    address immutable public USDC;

    struct CoverageInfo {
        uint256 coverageAmount;
        uint256 maturityDate; 
        address coverageHolder;
        bool wasRedeemed;
    }

    mapping(uint256 => CoverageInfo) public coverageInfo;
    mapping(address => bool) public isWhitelisted; // Whitelisting addresses getting coverage

    bool public fundingStarted = false;  // If LP already funded don't allow another deposit
    uint256 public poolStart = 0;  // Time that first coverage happened
    uint256 public reservesReleaseDate = 0;  // Date when LP can withdraw

    uint256 public totalReserves = 0;
    uint256 public availableReserves = 0;  // Funds that can be used for coverage (can multiply this by the ratio for subtracting by the actual amounts)
    uint256 public yieldedFunds = 0;  // Kept separate from reserve pool funds

    constructor(
        address registrar,
        string memory __baseURI,
        address _USDC,
        uint256 _coveragePeriod,  // In seconds
        uint256 _reservesLockupPeriod,  // In seconds
        uint256 _reserveRatio
    ) ModuleBase(registrar) ERC20("DenotaCoverageToken", "DCT"){
        _URI = __baseURI;
        USDC = _USDC;
        COVERAGE_PERIOD = _coveragePeriod;
        RESERVE_LOCKUP_PERIOD = _reservesLockupPeriod;
        MAX_RESERVE_BPS = _reserveRatio;
    }

    function processWrite(
        address caller,
        address _owner,
        uint256 notaId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata initData
    ) public override onlyRegistrar returns (uint256) {
        require(isWhitelisted[caller], "Not whitelisted");
        require(_owner == address(this), "Risk fee not paid to pool");
        require(currency == USDC, "Incorrect currency");
        require(escrowed == 0, "Escrow unsupported");
        
        (address coverageHolder, uint256 coverageAmount, uint256 riskScore) = abi.decode(
            initData,
            (address, uint256, uint256)
        );
        require(coverageAmount > 0, "No coverage");
        require(instant != 0 && (instant == (coverageAmount / 10_000) * riskScore), "Risk fee not paid");  // TODO ensure doesn't overflow

        uint256 scaledCoverageAmount = (coverageAmount * MAX_RESERVE_BPS) / 10_000;
        availableReserves -= scaledCoverageAmount; // underflow reverts (max_reserve_ratio has been exceeded)
        
        uint256 maturityDate = block.timestamp + COVERAGE_PERIOD;
        if (poolStart == 0) {
            poolStart = block.timestamp;
            reservesReleaseDate = block.timestamp + RESERVE_LOCKUP_PERIOD;
        } else {
            require(maturityDate <= reservesReleaseDate, "Coverage period elapsed");
        }

        yieldedFunds += instant;
        coverageInfo[notaId].coverageHolder = coverageHolder;
        coverageInfo[notaId].maturityDate = maturityDate;
        coverageInfo[notaId].coverageAmount = coverageAmount;
        return 0;
    }

    // TODO could change this to processCash();
    function claimCoverage(uint256 notaId) public {
        CoverageInfo storage coverage = coverageInfo[notaId];

        require(!coverage.wasRedeemed, "Already redeemed");
        require(block.timestamp < coverage.maturityDate, "Coverage expired");
        require(_msgSender() == coverage.coverageHolder, "Not coverage holder");

        IERC20(USDC).safeTransfer(
            coverage.coverageHolder,
            coverage.coverageAmount
        );

        coverage.wasRedeemed = true;
        // TODO need to deduct from reserves (available and yieldedFunds)
    }

    // Note: Can be called by anyone to sweep matured Nota coverage back into active funds
    function getYield(uint256 notaId) public {  // TODO inefficient
        CoverageInfo storage coverage = coverageInfo[notaId];

        require(!coverage.wasRedeemed, "Already redeemed");
        require(coverage.maturityDate <= block.timestamp, "Not matured yet");
        
        coverage.wasRedeemed = true;
        availableReserves += coverage.coverageAmount;  // Release active capital
    }

    function deposit(uint256 fundingAmount) public {
        require(!fundingStarted, "Pool already funded");

        IERC20(USDC).safeTransferFrom(_msgSender(), address(this), fundingAmount);

        totalReserves = fundingAmount;
        availableReserves += fundingAmount;
        fundingStarted = true;

        _mint(_msgSender(), fundingAmount);
    }

    function withdraw() public {
        // HACK: if the total supply isn't claimed the module is bricked (can't restart LP/Coverage pool)
        require(reservesReleaseDate >= block.timestamp);  // Yielding period is over, allow claims
        uint256 liquidityClaim = balanceOf(_msgSender());
        require(liquidityClaim != 0, "No LP tokens");
        // TODO ensure safe math
        uint256 claimPercentage = liquidityClaim / totalReserves; // Percentage of yield they are entitled to
        uint256 yieldClaim = yieldedFunds * claimPercentage; // TODO use safest math (round down)

        _burn(_msgSender(), liquidityClaim); // Withdraw() burns all the caller's tokens

        if (totalSupply() == 0){  // TODO consider a waiting period where this can be reset without supply=0
            fundingStarted = false;
            poolStart = 0;
            reservesReleaseDate = 0;
            availableReserves = 0;
            yieldedFunds = 0;
        }
        
        IERC20(USDC).safeTransfer(_msgSender(), liquidityClaim + yieldClaim);
    }

    // Admin can add an address to the whitelist
    function addToWhitelist(address _address) external onlyOwner {
        isWhitelisted[_address] = true;
    }

    // Admin can remove an address from the whitelist
    function removeFromWhitelist(address _address) external onlyOwner {
        isWhitelisted[_address] = false;
    }

    function coverageInfoCoverageAmount(uint256 notaId) public view returns(uint256){
        return coverageInfo[notaId].coverageAmount;
    }
    function coverageInfoMaturityDate(uint256 notaId) public view returns(uint256){
        return coverageInfo[notaId].maturityDate;
    }
    function coverageInfoCoverageHolder(uint256 notaId) public view returns(address){
        return coverageInfo[notaId].coverageHolder;
    }
    function coverageInfoWasRedeemed(uint256 notaId) public view returns(bool){
        return coverageInfo[notaId].wasRedeemed;
    }
}
