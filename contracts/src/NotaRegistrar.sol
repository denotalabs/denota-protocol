// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {INotaModule} from "./interfaces/INotaModule.sol";
import {INotaRegistrar} from "./interfaces/INotaRegistrar.sol";
import {NotaEncoding} from "./libraries/Base64Encoding.sol";
import {Nota} from "./libraries/DataTypes.sol";
import  "./ERC4906.sol";
import  "./NotaFees.sol";

contract NotaRegistrar is ERC4906, INotaRegistrar, NotaFees, NotaEncoding {
    using SafeERC20 for IERC20;
    
    mapping(uint256 => Nota) private _notas;
    uint256 public totalSupply;

    modifier isMinted(uint256 notaId) {
        if (notaId >= totalSupply) revert NotMinted();
        _;
    }

    constructor() ERC4906("Denota Protocol", "NOTA") {}

    function write(address currency, uint256 escrowed, uint256 instant, address owner,  address module, bytes calldata moduleData) public payable returns (uint256) {
        uint256 moduleFee = INotaModule(module).processWrite(msg.sender, owner, totalSupply, currency, escrowed, instant, moduleData);

        _transferTokens(escrowed, instant, currency, owner, moduleFee);
        _mint(owner, totalSupply);
        _notas[totalSupply] = Nota(escrowed, block.timestamp, currency, module);
        _moduleRevenue[module][currency] += moduleFee;

        emit Written(msg.sender, totalSupply, owner, instant, currency, escrowed, block.timestamp, moduleFee, module, moduleData);
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
        _safeTransfer(from, to, notaId, moduleTransferData);
        emit MetadataUpdate(notaId);
    }

    function fund(uint256 notaId, uint256 amount, uint256 instant, bytes calldata fundData) public payable isMinted(notaId) {
        Nota memory nota = _notas[notaId];
        address notaOwner = ownerOf(notaId);
        uint256 moduleFee = INotaModule(nota.module).processFund(msg.sender, notaOwner, amount, instant, notaId, nota, fundData);

        _transferTokens(amount, instant, nota.currency, notaOwner, moduleFee);
        _notas[notaId].escrowed += amount;
        _moduleRevenue[nota.module][nota.currency] += moduleFee;

        emit Funded(msg.sender, notaId, amount, instant, fundData, moduleFee, block.timestamp);
        emit MetadataUpdate(notaId);
    }

    function cash(uint256 notaId, uint256 amount, address to, bytes calldata cashData) public payable isMinted(notaId) {
        Nota memory nota = _notas[notaId];
        uint256 moduleFee = INotaModule(nota.module).processCash(msg.sender, ownerOf(notaId), to, amount, notaId, nota, cashData);
        
        uint256 totalAmount = amount + moduleFee;  // calced here since needed for check before transfer
        if (totalAmount > nota.escrowed) revert InsufficientEscrow(totalAmount, nota.escrowed);
        unchecked { _notas[notaId].escrowed -= totalAmount; } 
        _unescrowTokens(nota.currency, to, amount);
        _moduleRevenue[nota.module][nota.currency] += moduleFee;
        emit Cashed(msg.sender, notaId, to, amount, cashData, moduleFee, block.timestamp);
    }

    function approve( address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) isMinted(notaId) {
        if (to == msg.sender) revert SelfApproval();
        Nota memory nota = _notas[notaId];
        INotaModule(nota.module).processApproval(msg.sender, ownerOf(notaId), to, notaId, nota, "");
        _approve(to, notaId);
        emit MetadataUpdate(notaId);
    }
    
    function tokenURI(uint256 notaId) public view override isMinted(notaId) returns (string memory) {
        Nota memory nota = _notas[notaId];
        (string memory moduleAttributes, string memory moduleKeys) = INotaModule(nota.module).processTokenURI(notaId);
        return toJSON(nota, moduleAttributes, moduleKeys);
    }
    /*//////////////////////// HELPERS ///////////////////////////*/
    // NOTE: each throw on failure. Have additional checks here?
    function _escrowTokens(uint256 toEscrow, address currency) private {
        if (toEscrow > 0) {
                if (currency == address(0)) {
                    if (msg.value < toEscrow) revert InsufficientValue(toEscrow, msg.value);
                    // Transfer already done in tx
                } else {
                    // Transfer
                    IERC20(currency).safeTransferFrom(
                        msg.sender,
                        address(this),
                        toEscrow
                    );
                }
            }
    }
    function _instantTokens(address currency, uint256 instant, address recipient, uint256 escrow) private {
        if (instant > 0) {
                if (currency == address(0)) {
                    if (msg.value != instant + escrow) revert InsufficientValue(instant + escrow, msg.value);
                    // Transfer
                    (bool sent, ) = recipient.call{value: instant}(""); // forwards ETH to owner
                    if (!sent) revert SendFailed();
                } else {
                    // Transfer
                    IERC20(currency).safeTransferFrom(
                        msg.sender,
                        recipient,
                        instant
                    );
                }
            }
    }
    function _unescrowTokens(address currency, address to, uint256 amount) private {
        if (currency == address(0)) {
            (bool sent, ) = to.call{value: amount}("");
            if (!sent) revert SendFailed();
        } else {
            IERC20(currency).safeTransfer(to, amount);
        }
    }
    function _transferTokens(
        uint256 escrowed,
        uint256 instant,
        address currency,
        address recipient,
        uint256 moduleFee
    ) private {
        uint256 toEscrow = escrowed + moduleFee; // Module forces user to escrow moduleFee, even when escrowed == 0
        if (toEscrow + instant!= 0) {
            _escrowTokens(toEscrow, currency);
            _instantTokens(currency, instant, recipient, toEscrow);
        }
    }

    function _transferHookTakeFee(
        address from,
        address to,
        uint256 notaId,
        bytes memory moduleTransferData
    ) internal {
        if (moduleTransferData.length == 0)
            moduleTransferData = abi.encode("");
        address owner = ownerOf(notaId); // require(from == owner,  "") ?
        Nota memory nota = _notas[notaId]; // Better to assign than to index?
        // No approveOrOwner check, allow module to decide

        // Module hook
        uint256 moduleFee = INotaModule(nota.module).processTransfer(
            msg.sender,
            getApproved(notaId),
            owner,
            from,
            to,
            notaId,
            nota,
            moduleTransferData
        );

        // TODO ensure failure on 0 escrow but moduleFee (or should module handle that??)
        if (moduleFee > 0){
            _notas[notaId].escrowed -= moduleFee;  // If module doesn't revert then this will
            _moduleRevenue[nota.module][nota.currency] += moduleFee;
        }
        emit Transferred(notaId, owner, to, moduleFee, block.timestamp);

        // if (nota.escrowed > 0) {
        //     _notas[notaId].escrowed -= moduleFee;
        //     _moduleRevenue[nota.module][nota.currency] += moduleFee;
        // } else { // Must be case since fee's can't be taken without an escrow to take from
        //     emit Transferred(notaId, owner, to, 0, block.timestamp);
        // }
        // emit Transferred(notaId, owner, to, moduleFee, block.timestamp);
    }

    function metadataUpdate(uint256 notaId) external {
        Nota memory nota = _notas[notaId];
        require(msg.sender == nota.module, "NOT_MODULE");
        emit MetadataUpdate(notaId);
    }

    function notaInfo(
        uint256 notaId
    ) public view isMinted(notaId) returns (Nota memory) {
        return _notas[notaId];
    }
    function notaEscrowed(uint256 notaId) public view isMinted(notaId) returns (uint256) {
        return _notas[notaId].escrowed;
    }
    function notaCreatedAt(uint256 notaId) public view isMinted(notaId) returns (uint256) {
        return _notas[notaId].createdAt;
    }
    function notaCurrency(uint256 notaId) public view isMinted(notaId) returns (address) {
        return _notas[notaId].currency;
    }
    function notaModule(uint256 notaId) public view isMinted(notaId) returns (address) {
        return _notas[notaId].module;
    }
}

