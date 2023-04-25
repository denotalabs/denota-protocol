// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Events} from "./libraries/Events.sol";
import {IRegistrarGov} from "./interfaces/IRegistrarGov.sol";

// Idea Registrar could take different fees from different modules. Business related ones would be charged but not social ones?
contract RegistrarGov is Ownable, IRegistrarGov {
    using SafeERC20 for IERC20;
    mapping(address => mapping(address => uint256)) internal _moduleRevenue; // Could collapse this into a single mapping
    mapping(bytes32 => bool) internal _bytecodeWhitelist; // Question Can these be done without two mappings? Having both redeployable and static modules?
    mapping(address => bool) internal _addressWhitelist;
    mapping(address => bool) internal _tokenWhitelist;
    mapping(address => string) internal _moduleName;
    mapping(address => string) internal _tokenName;

    // uint256 public _writeFlatFee;
    // uint256 public registrarRevenue;

    // event MetadataUpdate(uint256 _tokenId);  // question how to update using this structure?
    // event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId); // todo need totalSupply

    function updateTokenName(
        address _token,
        string calldata tokenName
    ) public onlyOwner {
        _moduleName[_token] = tokenName;
    }

    function updateModuleName(
        address module,
        string calldata moduleName
    ) public onlyOwner {
        _moduleName[module] = moduleName;
    }

    function moduleWithdraw(
        address token,
        uint256 amount,
        address to
    ) external {
        require(_moduleRevenue[_msgSender()][token] >= amount, "INSUF_FUNDS");
        unchecked {
            _moduleRevenue[_msgSender()][token] -= amount;
        }
        IERC20(token).safeTransferFrom(address(this), to, amount);
    }

    function whitelistModule(
        address module,
        bool bytecodeAccepted,
        bool addressAccepted,
        string calldata moduleName
    ) external onlyOwner {
        require(module != address(0), "Address can't be zero");
        // Whitelist either bytecode or address
        require(
            bytecodeAccepted != addressAccepted || // Can't accept both, but
                !(bytecodeAccepted || addressAccepted), // can revoke both
            "CAN'T_ACCEPT_BOTH"
        );
        _bytecodeWhitelist[_returnCodeHash(module)] = bytecodeAccepted;
        _addressWhitelist[module] = addressAccepted;
        _moduleName[module] = moduleName;

        emit Events.ModuleWhitelisted(
            _msgSender(),
            module,
            bytecodeAccepted,
            addressAccepted,
            moduleName,
            block.timestamp
        );
    }

    function whitelistToken(
        address _token,
        bool accepted,
        string calldata tokenName
    ) external onlyOwner {
        // Whitelist for safety, modules can be more restrictive
        _tokenWhitelist[_token] = accepted;
        _tokenName[_token] = tokenName;
        emit Events.TokenWhitelisted(
            _msgSender(),
            _token,
            accepted,
            tokenName,
            block.timestamp
        );
    }

    function _returnCodeHash(address module) public view returns (bytes32) {
        bytes32 moduleCodeHash;
        assembly {
            moduleCodeHash := extcodehash(module)
        }
        return moduleCodeHash;
    }

    function validModule(address module) public view returns (bool) {
        return
            _addressWhitelist[module] ||
            _bytecodeWhitelist[_returnCodeHash(module)];
    }

    function tokenWhitelisted(address token) public view returns (bool) {
        return _tokenWhitelist[token];
    }

    function validWrite(
        address module,
        address token
    ) public view returns (bool) {
        return validModule(module) && tokenWhitelisted(token); // Valid module and whitelisted currency
    }

    function moduleWhitelisted(
        address module
    ) public view returns (bool, bool) {
        return (
            _addressWhitelist[module],
            _bytecodeWhitelist[_returnCodeHash(module)]
        );
    }
}
