// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IRegistrarGov} from "./interfaces/IRegistrarGov.sol";
import {IHooks} from "./interfaces/IHooks.sol";

abstract contract RegistrarGov is Ownable, IRegistrarGov {
    using SafeERC20 for IERC20;

    mapping(IHooks hook => mapping(address token => uint256 revenue)) internal _hookRevenue;
    mapping(IHooks hook => mapping(address token => uint256 totalRevenue)) internal _hookTotalRevenue;
    mapping(address token => uint256 revenue) internal _protocolRevenue;
    mapping(address token => uint256 totalRevenue) internal _protocolTotalRevenue;
    uint256 public constant MAX_PROTOCOL_FEE = 1000; // 10% in basis points
    uint256 internal _protocolFee; // In basis points (1/100 of a percent)
    string internal _contractURI;

    function setProtocolFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_PROTOCOL_FEE, "Fee exceeds maximum");
        _protocolFee = newFee;
        emit ProtocolFeeSet(newFee);
    }

    function protocolFee() external view returns (uint256) {
        return _protocolFee;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
        emit ContractURIUpdated();
    }

    function contractURI() external view returns (string memory) {
        return string.concat("data:application/json;utf8,", _contractURI);
    }

    function hookWithdraw(address token, uint256 amount, address to) external {
        _hookRevenue[IHooks(msg.sender)][token] -= amount; // reverts on underflow
        uint256 fee = (amount * _protocolFee) / 10000;
        _protocolRevenue[token] += fee;
        _protocolTotalRevenue[token] += fee;
        _hookTotalRevenue[IHooks(msg.sender)][token] += amount;
        IERC20(token).safeTransfer(to, amount - fee);
        emit HookRevenueCollected(msg.sender, token, amount, to, fee);
    }

    function protocolWithdraw(address token, uint256 amount, address to) external onlyOwner {
        require(amount <= _protocolRevenue[token], "Insufficient protocol revenue");
        _protocolRevenue[token] -= amount;
        IERC20(token).safeTransfer(to, amount);
        emit ProtocolRevenueCollected(token, amount, to);
    }

    function hookRevenue(IHooks hook, address currency) external view returns (uint256) {
        return _hookRevenue[hook][currency];
    }

    function hookTotalRevenue(IHooks hook, address currency) external view returns (uint256) {
        return _hookTotalRevenue[hook][currency];
    }

    function protocolRevenue(address currency) external view returns (uint256) {
        return _protocolRevenue[currency];
    }

    function protocolTotalRevenue(address currency) external view returns (uint256) {
        return _protocolTotalRevenue[currency];
    }
}
