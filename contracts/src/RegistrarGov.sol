// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IRegistrarGov} from "./interfaces/IRegistrarGov.sol";
import {INotaModule} from "./interfaces/INotaModule.sol";


contract RegistrarGov is Ownable, IRegistrarGov {
    using SafeERC20 for IERC20;

    mapping(INotaModule module => bool isWhitelisted) internal _moduleWhitelist;  // Could combine the two whitelists into one `address => bool`
    mapping(address token => bool isWhitelisted) internal _tokenWhitelist;  // Could also use a merkle tree for both of these

    function whitelistModule(
        INotaModule module,
        bool isWhitelisted
    ) external onlyOwner {
        require(_moduleWhitelist[module] != isWhitelisted, "REDUNDANT_WHITELIST");

        _moduleWhitelist[module] = isWhitelisted;

        emit ModuleWhitelisted(
            _msgSender(),
            module,
            isWhitelisted,
            block.timestamp
        );
    }

    function whitelistToken(
        address token,
        bool isWhitelisted
    ) external onlyOwner {
        require(_tokenWhitelist[token] != isWhitelisted, "REDUNDANT_WHITELIST");

        _tokenWhitelist[token] = isWhitelisted;

        emit TokenWhitelisted(
            _msgSender(),
            token,
            isWhitelisted,
            block.timestamp
        );
    }

    function tokenWhitelisted(address token) public view returns (bool) {
        return _tokenWhitelist[token];
    }

    function moduleWhitelisted(
        INotaModule module
    ) public view returns (bool) {
        return (
            _moduleWhitelist[module]
        );
    }

    function validWrite(
        INotaModule module,
        address token
    ) public view returns (bool) {
        return moduleWhitelisted(module) && tokenWhitelisted(token); // Valid module and whitelisted currency
    }

}
