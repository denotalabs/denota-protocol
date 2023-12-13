
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

    modifier isMinted(uint256 notaId) {
        if (notaId >= totalSupply) revert NotMinted();
        _;
    }

    constructor() ERC4906("Denota Protocol", "NOTA") {}

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

    function transferFrom(address from, address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) isMinted(notaId) {
        _transferHookTakeFee(from, to, notaId, abi.encode(""));
        _transfer(from, to, notaId);
        emit MetadataUpdate(notaId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 notaId,
        bytes memory moduleTransferData
    ) public override(ERC721, IERC721, INotaRegistrar) {
        _transferHookTakeFee(from, to, notaId, moduleTransferData);
        _safeTransfer(from, to, notaId, abi.encode(""));  // NOTE: seems like a vulnerability if passed through
        emit MetadataUpdate(notaId);
    }

    function fund(uint256 notaId, uint256 amount, uint256 instant, bytes calldata moduleBytes) public payable isMinted(notaId) {
        Nota memory nota = _notas[notaId];
        address notaOwner = ownerOf(notaId);
        uint256 moduleFee = nota.module.processFund(msg.sender, notaOwner, amount, instant, notaId, nota, moduleBytes);

        _transferTokens(nota.currency, notaOwner, amount, instant, moduleFee);
        _notas[notaId].escrowed += amount;
        _moduleRevenue[nota.module][nota.currency] += moduleFee;

        emit Funded(msg.sender, notaId, amount, instant, moduleBytes, moduleFee, block.timestamp);
        emit MetadataUpdate(notaId);
    }

    function cash(uint256 notaId, uint256 amount, address to, bytes calldata moduleBytes) public payable isMinted(notaId) {
        Nota memory nota = _notas[notaId];
        uint256 moduleFee = nota.module.processCash(msg.sender, ownerOf(notaId), to, amount, notaId, nota, moduleBytes);
        
        uint256 totalAmount = amount + moduleFee; 
        _notas[notaId].escrowed -= totalAmount;  // Removed from nota's escrow but moduleFee isn't sent
        _unescrowTokens(nota.currency, to, amount);
        _moduleRevenue[nota.module][nota.currency] += moduleFee;

        emit Cashed(msg.sender, notaId, to, amount, moduleBytes, moduleFee, block.timestamp);
        emit MetadataUpdate(notaId);
    }

    function approve(address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) isMinted(notaId) {
        Nota memory nota = _notas[notaId];
        nota.module.processApproval(msg.sender, ownerOf(notaId), to, notaId, nota, ""); // TODO remove the bytes argument
        _approve(to, notaId);
        emit MetadataUpdate(notaId);
    }
    
    function tokenURI(uint256 notaId) public view override isMinted(notaId) returns (string memory) {
        Nota memory nota = _notas[notaId];
        (string memory moduleAttributes, string memory moduleKeys) = INotaModule(nota.module).processTokenURI(notaId);
        return toJSON(
                Strings.toHexString(uint256(uint160(_notas[notaId].currency)), 20),
                itoa(_notas[notaId].escrowed),
                // itoa(_notas[notaId].createdAt),
                Strings.toHexString(uint256(uint160(address(_notas[notaId].module))), 20),
                moduleAttributes,
                moduleKeys
            );
    }
    /*//////////////////////// HELPERS ///////////////////////////*/
    function _escrowTokens(address currency, uint256 amount) private {
        if (amount > 0) {
                if (currency == address(0)) {
                    if (msg.value < amount) revert InsufficientValue(amount, msg.value);
                } else {
                    IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
                }
            }
    }
    function _unescrowTokens(address currency, address to, uint256 amount) private {
        if (amount > 0) {
            if (currency == address(0)) {
                (bool sent, ) = to.call{value: amount}("");
                if (!sent) revert SendFailed();
            } else {
                IERC20(currency).safeTransfer(to, amount);
            }
        }
    }
    function _instantTokens(address currency, address to, uint256 instant, uint256 escrowed) private {
        if (instant > 0) {
                if (currency == address(0)) {
                    uint256 totalTransfer = instant + escrowed;
                    if (msg.value != totalTransfer) revert InsufficientValue(totalTransfer, msg.value);
                    (bool sent, ) = to.call{value: instant}("");
                    if (!sent) revert SendFailed();
                } else {
                    IERC20(currency).safeTransferFrom(msg.sender, to, instant);
                }
            }
    }
    function _transferTokens(
        address currency,
        address recipient,
        uint256 escrowed,
        uint256 instant,
        uint256 moduleFee
    ) private {
        uint256 toEscrow = escrowed + moduleFee;
        if (toEscrow + instant != 0) { // Coupled since native instant also needs escrow amount transferred (single transfer in function call)
            _escrowTokens(currency, toEscrow);
            _instantTokens(currency, recipient, instant, toEscrow);
        }
    }
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

        if (moduleFee > 0){
            _notas[notaId].escrowed -= moduleFee;  // If module doesn't revert then this will
            _moduleRevenue[nota.module][nota.currency] += moduleFee;
        }
        emit Transferred(notaId, owner, to, moduleFee, block.timestamp);
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
    ) public view isMinted(notaId) returns (Nota memory) {
        return _notas[notaId];
    }

    function notaEscrowed(uint256 notaId) public view isMinted(notaId) returns (uint256) {
        return _notas[notaId].escrowed;
    }

    function notaCurrency(uint256 notaId) public view isMinted(notaId) returns (address) {
        return _notas[notaId].currency;
    }

    function notaModule(uint256 notaId) public view isMinted(notaId) returns (INotaModule) {
        return _notas[notaId].module;
    }
}

