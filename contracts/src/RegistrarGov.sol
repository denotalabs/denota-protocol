// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IRegistrarGov} from "./interfaces/IRegistrarGov.sol";
import {INotaModule} from "./interfaces/INotaModule.sol";

// TODO setting contractURI makes tests hand for some reason
contract RegistrarGov is Ownable, IRegistrarGov {
    using SafeERC20 for IERC20;

    mapping(bytes32 module => bool isWhitelisted) internal _codeHashWhitelist;  // Could combine the two whitelists into one `address => bool`
    string internal _contractURI;

    event ContractURIUpdated();

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
        emit ContractURIUpdated();
    }

    function whitelistModule(INotaModule module, bool isWhitelisted) external onlyOwner {
        bytes32 codeHash;
        assembly { codeHash := extcodehash(module) }

        require(_codeHashWhitelist[codeHash] != isWhitelisted, "REDUNDANT_WHITELIST");
        _codeHashWhitelist[codeHash] = isWhitelisted;

        emit ModuleWhitelisted(_msgSender(), module, isWhitelisted);
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

    function moduleWhitelisted(INotaModule module) public view returns (bool) {
        bytes32 codeHash;
        assembly { codeHash := extcodehash(module) }
        return _codeHashWhitelist[codeHash];
    }

    function validWrite(
        INotaModule module,
        address token
    ) public view returns (bool) {
        return moduleWhitelisted(module) && tokenWhitelisted(token);
    }

}
