
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {INotaModule} from "./interfaces/INotaModule.sol";
import {INotaRegistrar} from "./interfaces/INotaRegistrar.sol";
import {NotaEncoding} from "./libraries/Base64Encoding.sol";
import {Nota} from "./libraries/DataTypes.sol";
import  "./RegistrarGov.sol";
import  "./ERC4906.sol";

contract NotaRegistrar is ERC4906, INotaRegistrar, NotaEncoding, RegistrarGov {
    using SafeERC20 for IERC20;
    
    mapping(INotaModule => mapping(address => uint256)) private _moduleRevenue;
    mapping(uint256 => Nota) private _notas;
    uint256 public totalSupply;

    modifier exists(uint256 notaId) {
        if (_ownerOf(notaId) == address(0)) revert NonExistent();
        _;
    }

    constructor() ERC4906("Denota Protocol", "NOTA") {}

    /**
     * @notice Mints a Nota and transfers tokens
     * @dev Requires module & currency whitelisted, and sends instant tokens to `owner`
     */
    function write(address currency, uint256 escrowed, uint256 instant, address owner, INotaModule module, bytes calldata moduleBytes) public payable returns (uint256) {
        require(validWrite(module, currency), "INVALID_WRITE");
        uint256 moduleFee = module.processWrite(msg.sender, owner, totalSupply, currency, escrowed, instant, moduleBytes);

        _transferTokens(currency, owner, escrowed, instant, moduleFee);
        _mint(owner, totalSupply);
        _notas[totalSupply] = Nota(escrowed, currency, module);
        
        _moduleRevenue[module][currency] += moduleFee;

        emit Written(msg.sender, totalSupply, owner, instant, currency, escrowed, block.timestamp, moduleFee, module, moduleBytes);
        unchecked { return totalSupply++; }
    }

    /**
     * @notice Standard ERC721 transfer function
     * @dev Assumes the module enforces the transfer requirements (isApprovedOrOwner)
     */
    function transferFrom(address from, address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) exists(notaId) {
        _transferHookTakeFee(from, to, notaId, abi.encode(""));
        _transfer(from, to, notaId);
        emit MetadataUpdate(notaId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 notaId,
        bytes memory moduleBytes
    ) public override(ERC721, IERC721, INotaRegistrar) {
        _transferHookTakeFee(from, to, notaId, moduleBytes);
        _safeTransfer(from, to, notaId, abi.encode(""));
        emit MetadataUpdate(notaId);
    }

    /**
     * @notice 
     * @dev No requirements except what the module enforces
     */
    function fund(uint256 notaId, uint256 amount, uint256 instant, bytes calldata moduleBytes) public payable exists(notaId) {
        Nota memory nota = _notas[notaId];
        address notaOwner = ownerOf(notaId);
        uint256 moduleFee = nota.module.processFund(msg.sender, notaOwner, amount, instant, notaId, nota, moduleBytes);

        _transferTokens(nota.currency, notaOwner, amount, instant, moduleFee);
        _notas[notaId].escrowed += amount;
        _moduleRevenue[nota.module][nota.currency] += moduleFee;

        emit Funded(msg.sender, notaId, amount, instant, moduleBytes, moduleFee, block.timestamp);
        emit MetadataUpdate(notaId);
    }

    /**
     * @notice 
     * @dev No requirements except what the module enforces
     */
    function cash(uint256 notaId, uint256 amount, address to, bytes calldata moduleBytes) public payable exists(notaId) {
        Nota memory nota = _notas[notaId];
        uint256 moduleFee = nota.module.processCash(msg.sender, ownerOf(notaId), to, amount, notaId, nota, moduleBytes);
        
        uint256 totalAmount = amount + moduleFee; 
        _notas[notaId].escrowed -= totalAmount;  // Removed from nota's escrow but moduleFee isn't sent
        _unescrowTokens(nota.currency, to, amount);
        _moduleRevenue[nota.module][nota.currency] += moduleFee;

        emit Cashed(msg.sender, notaId, to, amount, moduleBytes, moduleFee, block.timestamp);
        emit MetadataUpdate(notaId);
    }

    function approve(address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) exists(notaId) {
        Nota memory nota = _notas[notaId];
        nota.module.processApproval(msg.sender, ownerOf(notaId), to, notaId, nota, "");

        ERC721.approve(to, notaId);  // Keep checks? Is owner or operator && to != owner
        emit MetadataUpdate(notaId);
    }
    
    function tokenURI(uint256 notaId) public view override exists(notaId) returns (string memory) {
        Nota memory nota = _notas[notaId];
        (string memory moduleAttributes, string memory moduleKeys) = INotaModule(nota.module).processTokenURI(notaId);
        
        return toJSON(
                Strings.toHexString(uint256(uint160(_notas[notaId].currency)), 20),
                itoa(_notas[notaId].escrowed),
                Strings.toHexString(uint256(uint160(address(_notas[notaId].module))), 20),
                moduleAttributes,
                moduleKeys
            );
    }
    /*//////////////////////// HELPERS ///////////////////////////*/
    function _transferHookTakeFee(
        address from,
        address to,
        uint256 notaId,
        bytes memory moduleBytes
    ) private {
        if (moduleBytes.length == 0) moduleBytes = abi.encode("");
        Nota memory nota = _notas[notaId];
        address owner = ownerOf(notaId);
        uint256 moduleFee = INotaModule(nota.module).processTransfer(msg.sender, getApproved(notaId), owner, from, to, notaId, nota, moduleBytes);

        _notas[notaId].escrowed -= moduleFee;
        _moduleRevenue[nota.module][nota.currency] += moduleFee;  // NOTE could do this unchecked
        emit Transferred(notaId, owner, to, moduleFee, block.timestamp);
    }

    function _instantTokens(address currency, address to, uint256 instant) private {
        if (instant > 0) IERC20(currency).safeTransferFrom(msg.sender, to, instant);
    }
    function _escrowTokens(address currency, uint256 toEscrow) private {
        if (toEscrow > 0) IERC20(currency).safeTransferFrom(msg.sender, address(this), toEscrow);
    }
    function _unescrowTokens(address currency, address to, uint256 amount) private {
        if (amount > 0) IERC20(currency).safeTransfer(to, amount);
    }
    function _transferTokens(
        address currency,
        address recipient,
        uint256 escrowed,
        uint256 instant,
        uint256 moduleFee
    ) private {
        uint256 toEscrow = escrowed + moduleFee;
        _escrowTokens(currency, toEscrow);
        _instantTokens(currency, recipient, instant);
    }

    function metadataUpdate(uint256 notaId) external {
        Nota memory nota = _notas[notaId];
        require(INotaModule(msg.sender) == nota.module, "NOT_MODULE");
        emit MetadataUpdate(notaId);
    }

    function moduleRevenue(INotaModule module, address currency) public view returns(uint256) {
        return _moduleRevenue[module][currency];
    }

    function moduleWithdraw(address token, uint256 amount, address to) external {
        _moduleRevenue[INotaModule(msg.sender)][token] -= amount;  // reverts on underflow
        IERC20(token).safeTransferFrom(address(this), to, amount);
    }

    function notaInfo(
        uint256 notaId
    ) public view exists(notaId) returns (Nota memory) {
        return _notas[notaId];
    }

    function notaEscrowed(uint256 notaId) public view exists(notaId) returns (uint256) {
        return _notas[notaId].escrowed;
    }

    function notaCurrency(uint256 notaId) public view exists(notaId) returns (address) {
        return _notas[notaId].currency;
    }

    function notaModule(uint256 notaId) public view exists(notaId) returns (INotaModule) {
        return _notas[notaId].module;
    }
}