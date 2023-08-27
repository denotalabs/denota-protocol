// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "./NotaRegistrar.sol";


// If 100k USDC is to be purchased, AT LEAST 100k USDC (minus discount) must be deposited as idle funds. 
// These funds should become active when a bond purchase is made in exchange for the idle funds

// Who deposited and how much into the idle funds should be tracked by the contract so they can withdraw
// If their idle funds becomes active, they should be given shares but not allowed to withdraw until the funds become idle again
// How to determine the redeeming of shares for mature tokens? Seems like there needs to be a way to update the total bond value has matured
contract BondAMM is ERC20Burnable {
    NotaRegistrar public bondToken;
    IERC20 public currencyToken;

    uint256 public activeFunds = 0;  // Funds that were used to purchase bonds
    uint256 public idleFunds = 0;  // Funds used to purchase future bonds

    uint256 public discount = 10; // 10% discount on bond purchases
    uint256 public constant DISCOUNT_STEP = 5;  // Automated discount increase per bond default

    uint256 public totalBondCount = 0;
    uint256 public totalMaturedCount = 0;
    uint256 public totalDefaultCount = 0;
    uint256 public totalBondValue = 0;  // Including pending bonds
    uint256 public totalDefaultValue = 0;
    uint256 public totalMaturedValue = 0;

    mapping(address => uint256) public userIdleFunds; // Tracks the idle funds of each user  // Question: do shares get calculated by percent of idle funds a user has or percent of active?

    event BondDefaulted(uint256 bondId);
    event BondMatured(uint256 bondId);

    constructor(address _bondToken, address _currencyToken) ERC20("BondShares", "BSHR") {
        bondToken = NotaRegistrar(_bondToken);
        currencyToken = IERC20(_currencyToken);
    }

    function depositBond(uint256 bondId) external {
        // Transfer bond ownership to this contract
        bondToken.transferFrom(msg.sender, address(this), bondId);

        uint256 bondValue = _getBondValue(bondId);
        uint256 currentDiscount = getDynamicDiscount(); 
        uint256 discountedValue = bondValue * currentDiscount / 100;

        require(idleFunds >= bondValue - discountedValue, "Not enough funds in the pool to buy the bond");

        // Transfer discounted amount to bond depositor
        currencyToken.transfer(msg.sender, bondValue - discountedValue);

        // Adjust fund tracking
        activeFunds += bondValue;
        idleFunds -= (bondValue - discountedValue);
        totalBondValue += bondValue;
        totalBondCount += 1;
    }

    function provideLiquidity(uint256 amount) external {
        require(currencyToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        uint256 newShares = _calculateShares(amount);
        _mint(msg.sender, newShares);
        userIdleFunds[msg.sender] += amount; 
        idleFunds += amount;
    }

    function redeemBond(uint256 bondId) external {
        require(bondToken.ownerOf(bondId) == address(this), "Bond not held by the contract");

        uint256 bondValue = _getBondValue(bondId);
        require(idleFunds >= bondValue, "Not enough funds to redeem the bond");

        bondToken.transferFrom(address(this), msg.sender, bondId);
        currencyToken.transfer(msg.sender, bondValue);

        activeFunds -= bondValue;
        idleFunds -= bondValue;
        totalBondValue -= bondValue;
        totalBondCount -= 1;
    }

    function withdrawLiquidity(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient bond shares");
        require(idleFunds >= amount, "Insufficient liquidity");

        _burn(msg.sender, amount);
        currencyToken.transfer(msg.sender, amount);
        userIdleFunds[msg.sender] -= amount;
        idleFunds -= amount;
    }

    function bondDefaulted(uint256 bondId) external {
        emit BondDefaulted(bondId);

        uint256 bondValue = _getBondValue(bondId);
        activeFunds -= bondValue;
        totalBondValue -= bondValue;

        if (discount + DISCOUNT_STEP <= 100) {
            discount += DISCOUNT_STEP;
        }
        totalDefaultCount += 1;
    }
    
    function bondMatured(uint256 bondId) external {
        emit BondMatured(bondId);

        uint256 bondValue = _getBondValue(bondId);
        activeFunds -= bondValue;
        idleFunds += bondValue;
        totalMaturedValue += bondValue;
    }

    function getDynamicDiscount() public view returns (uint256) {
        if (totalBondCount == 0) {
            return discount;
        }

        uint256 riskFactor = (totalDefaultCount * 100) / totalBondCount;
        uint256 dynamicDiscount = discount + riskFactor * DISCOUNT_STEP;

        return (dynamicDiscount > 100) ? 100 : dynamicDiscount;
    }

    function _calculateShares(uint256 depositAmount) internal view returns (uint256) {
        /// Maybe shares has a formula. Shares are virtual but based on user's idle funds vs matured funds?
        return (totalBondValue == 0) 
            ? depositAmount
            : depositAmount * totalSupply() / totalBondValue; 
    }

    function _getBondValue(uint256 bondId) internal view returns (uint256) {
        return bondToken.notaEscrowed(bondId); // e.g., 1 token
    }
}
