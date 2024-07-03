// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IRegistrarGov} from "./interfaces/IRegistrarGov.sol";
import {IHooks} from "./interfaces/IHooks.sol";

// TODO setting contractURI makes tests hang for some reason
contract RegistrarGov is Ownable, IRegistrarGov {
    using SafeERC20 for IERC20;

    mapping(IHooks hook => mapping(address token => uint256 revenue)) internal _hookRevenue;
    mapping(IHooks hook => mapping(address token => uint256 totalRevenue)) internal _hookTotalRevenue;
    mapping(address token => uint256 revenue) internal _protocolRevenue;
    mapping(address token => uint256 totalRevenue) internal _protocolTotalRevenue;
    mapping(bytes32 hook => bool isWhitelisted) internal _codeHashWhitelist;
    uint256 public constant MAX_PROTOCOL_FEE = 1000; // 10% in basis points
    uint256 public protocolFee; // In basis points (1/100 of a percent)
    string internal _contractURI;

    event ContractURIUpdated();
    event ProtocolFeeSet(uint256 newFee);
    event HookWithdraw(address indexed hook, address indexed token, uint256 amount, address indexed to, uint256 fee);
    event ProtocolRevenueCollected(address indexed token, uint256 amount, address indexed to);

    function setProtocolFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_PROTOCOL_FEE, "Fee exceeds maximum");
        protocolFee = newFee;
        emit ProtocolFeeSet(newFee);
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
        emit ContractURIUpdated();
    }

    function contractURI() external view returns (string memory) {
        return string.concat("data:application/json;utf8,", _contractURI);
    }

    function whitelistHook(IHooks hook, bool isWhitelisted) external onlyOwner {
        bytes32 codeHash;
        assembly { codeHash := extcodehash(hook) }

        require(_codeHashWhitelist[codeHash] != isWhitelisted, "REDUNDANT_WHITELIST");
        _codeHashWhitelist[codeHash] = isWhitelisted;

        emit HookWhitelisted(_msgSender(), hook, isWhitelisted);
    }

    function whitelistToken(address token, bool isWhitelisted) external onlyOwner {
        bytes32 codeHash;
        assembly { codeHash := extcodehash(token) }

        require(_codeHashWhitelist[codeHash] != isWhitelisted, "REDUNDANT_WHITELIST");

        _codeHashWhitelist[codeHash] = isWhitelisted;

        emit TokenWhitelisted(_msgSender(), token, isWhitelisted);
    }

    function tokenWhitelisted(address token) public view returns (bool) {
        bytes32 codeHash;
        assembly { codeHash := extcodehash(token) }
        return _codeHashWhitelist[codeHash];
    }

    function hookWhitelisted(IHooks hook) public view returns (bool) {
        bytes32 codeHash;
        assembly { codeHash := extcodehash(hook) }
        return _codeHashWhitelist[codeHash];
    }

    function validWrite(
        IHooks hook,
        address token
    ) public view returns (bool) {
        return hookWhitelisted(hook) && tokenWhitelisted(token);
    }

    function hookWithdraw(address token, uint256 amount, address to) external {
        _hookRevenue[IHooks(msg.sender)][token] -= amount;  // reverts on underflow
        uint256 fee = (amount * protocolFee) / 10000;
        uint256 amountAfterFee = amount - fee;
        _protocolRevenue[token] += fee;
        _protocolTotalRevenue[token] += fee;
        _hookTotalRevenue[IHooks(msg.sender)][token] += amount;
        IERC20(token).safeTransfer(to, amountAfterFee);
        emit HookWithdraw(msg.sender, token, amount, to, fee);
    }

    function collectProtocolRevenue(address token, uint256 amount, address to) external onlyOwner {
        require(amount <= _protocolRevenue[token], "Insufficient protocol revenue");
        _protocolRevenue[token] -= amount;
        IERC20(token).safeTransfer(to, amount);
        emit ProtocolRevenueCollected(token, amount, to);
    }

    function hookRevenue(IHooks hook, address currency) external view returns(uint256) {
        return _hookRevenue[hook][currency];
    }

    function hookTotalRevenue(IHooks hook, address currency) external view returns(uint256) {
        return _hookTotalRevenue[hook][currency];
    }

    function protocolRevenue(address currency) external view returns(uint256) {
        return _protocolRevenue[currency];
    }

    function protocolTotalRevenue(address currency) external view returns(uint256) {
        return _protocolTotalRevenue[currency];
    }
}