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
    mapping(bytes32 hook => bool isWhitelisted) internal _codeHashWhitelist;
    string internal _contractURI;

    event ContractURIUpdated();
    event HookWithdraw(address indexed hook, address indexed token, uint256 amount, address indexed to);

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
        if (amount > 0) IERC20(token).safeTransfer(to, amount);
        emit HookWithdraw(msg.sender, token, amount, to);
    }

    function hookRevenue(IHooks hook, address currency) external view returns(uint256) {
        return _hookRevenue[hook][currency];
    }

}
