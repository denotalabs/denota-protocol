// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IRegistrarGov} from "./interfaces/IRegistrarGov.sol";
import {INotaModule} from "./interfaces/INotaModule.sol";

contract RegistrarGov is Ownable, IRegistrarGov {
    using SafeERC20 for IERC20;

    mapping(INotaModule => bool) internal _addressWhitelist;
    mapping(address => bool) internal _tokenWhitelist;

    function whitelistModule(
        INotaModule module,
        bool addressAccepted
    ) external onlyOwner {
        _addressWhitelist[module] = addressAccepted;

        emit ModuleWhitelisted(
            _msgSender(),
            module,
            addressAccepted,
            block.timestamp
        );
    }

    function whitelistToken(
        address _token,
        bool accepted
    ) external onlyOwner {
        _tokenWhitelist[_token] = accepted;
        emit TokenWhitelisted(
            _msgSender(),
            _token,
            accepted,
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
            _addressWhitelist[module]
        );
    }

    function validWrite(
        INotaModule module,
        address token
    ) public view returns (bool) {
        return moduleWhitelisted(module) && tokenWhitelisted(token); // Valid module and whitelisted currency
    }

}
