// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

// Assumes: a single LP, a single liquidity deposit, a single lockup period (with endDate buffer=endDate  - coverage maturity), coverage is fully backed
// TODO add reserve pool specific events
contract Coverage is Ownable, ModuleBase {
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
    address public liquidityProvider;
    uint256 public poolStart = 0;  // Time that first coverage happened
    uint256 public liquidityReleaseDate;  // Date when LP can withdraw

    uint256 public availableFunds = 0;  // Funds that can be used for coverage
    uint256 public yieldedFunds = 0;

    uint256 public liquidityLockupPeriod;  // LP locks for 6 months
    uint256 public coveragePeriod;  // Nota coverage period
    address public usdc;

    constructor(
        address registrar,
        DataTypes.WTFCFees memory _fees,
        string memory __baseURI,
        address _usdc,
        uint256 _coveragePeriod,  // In seconds
        uint256 _liquidityLockupPeriod  // In seconds
    ) ModuleBase(registrar, _fees) {
        _URI = __baseURI;
        usdc = _usdc;
        coveragePeriod = _coveragePeriod;
        liquidityLockupPeriod = _liquidityLockupPeriod;
    }

    function processWrite(
        address caller,
        address _owner,
        uint256 cheqId,
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
            liquidityReleaseDate = block.timestamp + liquidityLockupPeriod;
        } else {
            require(maturityDate <= liquidityReleaseDate);
        }

        (address holder, uint256 amount, uint256 riskScore) = abi.decode(
            initData,
            (address, uint256, uint256)
        );  // TODO do we need the risk score right now?

        require(instant == (amount / 10000) * riskScore, "Risk fee not paid");
        
        availableFunds -= amount;  // Throws on underflow (using pragma >0.8)
        yieldedFunds += instant;

        coverageInfo[cheqId].coverageHolder = holder;
        coverageInfo[cheqId].maturityDate = maturityDate;
        coverageInfo[cheqId].coverageAmount = amount;
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

        availableFunds += fundingAmount;
        liquidityProvider = _msgSender();
        fundingStarted = true;

        // LPs receive pool tokens in return TODO: figure out token issuance and redemption
    }

    // Note: Can be called by anyone to sweep matured Nota coverage back into active funds
    function getYield(uint256 notaId) public {  // TODO inefficient
        CoverageInfo storage coverage = coverageInfo[notaId];

        require(!coverage.wasRedeemed);
        require(coverage.maturityDate <= block.timestamp);
        
        availableFunds += coverage.coverageAmount;
    }

    function withdraw() public {
        require(_msgSender() == liquidityProvider);
        require(liquidityReleaseDate >= block.timestamp);
        
        fundingStarted = false;
        liquidityProvider = address(0);
        poolStart = 0;
        liquidityReleaseDate = 0;
        availableFunds = 0;
        yieldedFunds = 0;
        
        IERC20(usdc).safeTransfer(liquidityProvider, availableFunds + yieldedFunds);
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
