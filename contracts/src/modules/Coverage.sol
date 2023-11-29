// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
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
    uint256 public reservesReleaseDate;  // Date when LP can withdraw

    uint256 public totalReserves = 0; 
    uint256 public availableReserves = 0;  // Funds that can be used for coverage (can multiply this by the ratio for subtracting by the actual amounts)
    uint256 public yieldedFunds = 0;  // Kept separate reserve pool funds

    uint256 public reservesLockupPeriod;  // LP locks for 6 months
    uint256 public coveragePeriod;  // Nota coverage period
    uint256 public reserveRatio;  // In BPS -> (reserveRatio / 10_000)%
    address public usdc;

    constructor(
        address registrar,
        DataTypes.WTFCFees memory _fees,
        string memory __baseURI,
        address _usdc,
        uint256 _coveragePeriod,  // In seconds
        uint256 _reservesLockupPeriod,  // In seconds
        uint256 _reserveRatio
    ) ModuleBase(registrar, _fees) ERC20("DenotaCoverageToken", "DCT"){
        _URI = __baseURI;
        usdc = _usdc;
        coveragePeriod = _coveragePeriod;
        reservesLockupPeriod = _reservesLockupPeriod;
        reserveRatio = _reserveRatio;
    }

    function processWrite(
        address caller,
        address _owner,
        uint256 notaId,
        address currency,
        uint256 /*escrowed*/,
        uint256 instant,
        bytes calldata initData
    ) public override onlyRegistrar returns (uint256) {
        require(isWhitelisted[caller], "Not whitelisted");
        require(_owner == address(this), "Risk fee not paid to pool"); // TODO registrar assumes that the owner is the one being paid
        require(currency == usdc, "Incorrect currency");

        uint256 maturityDate = block.timestamp + coveragePeriod;

        if (poolStart == 0) {
            poolStart = block.timestamp;
            reservesReleaseDate = block.timestamp + reservesLockupPeriod;
        } else {
            require(maturityDate <= reservesReleaseDate);
        }

        (address holder, uint256 amount, uint256 riskScore) = abi.decode(
            initData,
            (address, uint256, uint256)
        );

        require(instant == (amount / 10_000) * riskScore, "Risk fee not paid");

        uint256 currentCoverage = (totalReserves - availableReserves);
        uint256 newCoverage = currentCoverage + amount;

        uint256 newReserveBPS = (totalReserves / newCoverage) * 100;  // 1_000 / 800 => 800 * 100 => 8_000
        if (newReserveBPS < reserveRatio) revert("Exceeds reserve ratio");

        uint256 scaledAmount = (amount * reserveRatio) / 10_000;
        availableReserves -= scaledAmount; // scale down by reserve ratio (amount=100 => amount=5 if rR=2_000)

        yieldedFunds += instant;
        coverageInfo[notaId].coverageHolder = holder;
        coverageInfo[notaId].maturityDate = maturityDate;
        coverageInfo[notaId].coverageAmount = amount;
        return 0;
    }

    function claimCoverage(uint256 notaId) public {
        CoverageInfo storage coverage = coverageInfo[notaId];

        require(!coverage.wasRedeemed);
        require(block.timestamp < coverage.maturityDate);
        // require(_msgSender() == coverage.coverageHolder);  // Question: require the coverage holder to call this?

        // MVP: just send funds to the holder (doesn't scale but makes the demo easier)
        IERC20(usdc).safeTransfer(
            coverage.coverageHolder,
            coverage.coverageAmount
        );

        coverage.wasRedeemed = true;
    }

    function deposit(uint256 fundingAmount) public {
        require(!fundingStarted, "Pool already funded");

        IERC20(usdc).safeTransferFrom(_msgSender(), address(this), fundingAmount);

        totalReserves = fundingAmount;
        availableReserves += fundingAmount;
        fundingStarted = true;

        _mint(_msgSender(), fundingAmount);
    }

    // Note: Can be called by anyone to sweep matured Nota coverage back into active funds
    function getYield(uint256 notaId) public {  // TODO inefficient
        CoverageInfo storage coverage = coverageInfo[notaId];

        require(!coverage.wasRedeemed);
        require(coverage.maturityDate <= block.timestamp);
        
        availableReserves += coverage.coverageAmount;
    }

    function withdraw() public {
        // HACK: if the total supply isn't claimed the module is bricked (can't restart LP/Coverage pool)
        require(reservesReleaseDate >= block.timestamp);  // Yielding period is over, allow claims
        uint256 liquidityClaim = balanceOf(_msgSender());
        uint256 claimPercentage = liquidityClaim / totalReserves;  // Percentage of yield they are entitled to
        uint256 yieldClaim = yieldedFunds * claimPercentage; // TODO use safest math (round down)

        _burn(_msgSender(), liquidityClaim); // Withdraw() burns all the caller's tokens

        if (totalSupply() == 0){
            fundingStarted = false;
            poolStart = 0;
            reservesReleaseDate = 0;
            availableReserves = 0;
            yieldedFunds = 0;
        }
        
        IERC20(usdc).safeTransfer(_msgSender(), liquidityClaim + yieldClaim);
    }

    // Admin can add an address to the whitelist
    function addToWhitelist(address _address) external onlyOwner {
        isWhitelisted[_address] = true;
    }

    // Admin can remove an address from the whitelist
    function removeFromWhitelist(address _address) external onlyOwner {
        isWhitelisted[_address] = false;
    }

    function processTransfer(
        address caller,
        address approved,
        address owner,
        address /*from*/,
        address /*to*/,
        uint256 /*cheqId*/,
        address currency,
        uint256 escrowed,
        uint256 /*createdAt*/,
        bytes memory data
    ) public override onlyRegistrar returns (uint256) {
        return 0;
    }

    function processFund(
        address /*caller*/,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 cheqId,
        DataTypes.Nota calldata cheq,
        bytes calldata initData
    ) public override onlyRegistrar returns (uint256) {
        return 0;
    }

    function processCash(
        address /*caller*/,
        address /*owner*/,
        address /*to*/,
        uint256 /*amount*/,
        uint256 /*cheqId*/,
        DataTypes.Nota calldata /*cheq*/,
        bytes calldata /*initData*/
    ) public view override onlyRegistrar returns (uint256) {
        return 0;
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*cheqId*/,
        DataTypes.Nota calldata /*cheq*/,
        bytes memory /*initData*/
    ) public view override onlyRegistrar {
        // if (caller != owner) revert;
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        return "";
    }
}
