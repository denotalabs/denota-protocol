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

// TODO replace SafeERC20 to UniV4.currency
// TODO remove Context dependancy
// TODO noDelegateCall in WTFCAB
// TODO use struct in write (write(INotaRegistrar.NotaParams({currency, escrowed, owner, module}), instant /*, instantRecipient*/, writeData)
// TODO refactor cashing token transfer logic into an internal function for readability
contract NotaRegistrar is ERC4906, INotaRegistrar, NotaFees, NotaEncoding {
    using SafeERC20 for IERC20;
    
    mapping(uint256 => Nota) private _notas;
    uint256 public totalSupply;

    modifier isMinted(uint256 notaId) {  // Question: Allow burned Notas to be interacted with? Otherwise use ERC721._exists()
        if (notaId >= totalSupply) revert NotMinted();
        _;
    }

    constructor() ERC4906("Denota", "NOTA") {}

    function write(address currency, uint256 escrowed, uint256 instant, address owner,  address module, bytes calldata moduleData) public payable returns (uint256) {
        uint256 moduleFee = INotaModule(module).processWrite(msg.sender, owner, totalSupply, currency, escrowed, instant, moduleData);

        _transferTokens(escrowed, instant, currency, owner, moduleFee, module);
        _mint(owner, totalSupply);
        _notas[totalSupply] = Nota(escrowed, block.timestamp, currency, module);

        emit Written(msg.sender, totalSupply, owner, instant, currency, escrowed, block.timestamp, moduleFee, module, moduleData);
        unchecked { return totalSupply++; }
    }

    function transferFrom(address from, address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) isMinted(notaId) {
        _transferHookTakeFee(from, to, notaId, abi.encode(""));
        _transfer(from, to, notaId);
        emit MetadataUpdate(notaId);
    }

    function safeTransferFrom(  // Question: is this needed?
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
        address tokenOwner = ownerOf(notaId);
        uint256 moduleFee = INotaModule(nota.module).processFund(msg.sender, tokenOwner, amount, instant, notaId, nota, fundData);

        _transferTokens(amount, instant, nota.currency, tokenOwner, moduleFee, nota.module);
        _notas[notaId].escrowed += amount;

        emit Funded(msg.sender, notaId, amount, instant, fundData, moduleFee, block.timestamp);
        emit MetadataUpdate(notaId);
    }

    function cash(uint256 notaId, uint256 amount, address to, bytes calldata cashData) public payable isMinted(notaId) {
        Nota memory nota = _notas[notaId];

        uint256 moduleFee = INotaModule(nota.module).processCash( msg.sender, ownerOf(notaId), to, amount, notaId, nota, cashData);
        
        // _transferTokens(amount + moduleFee, instant, nota.currency, tokenOwner, moduleFee, nota.module);
        uint256 totalAmount = amount + moduleFee;

        if (totalAmount > nota.escrowed)
            revert InsufficientEscrow(totalAmount, nota.escrowed);
        unchecked {
            _notas[notaId].escrowed -= totalAmount;
        } 
        if (nota.currency == address(0)) {
            (bool sent, ) = to.call{value: amount}("");
            if (!sent) revert SendFailed();
        } else {
            IERC20(nota.currency).safeTransfer(to, amount);
        }
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
    function _transferTokens(  // Question: should this be broken into separate functions? What about the fee
        uint256 escrowed,
        uint256 instant,
        address currency,
        address payer,
        uint256 moduleFee,
        address module
    ) private {
        uint256 toEscrow = escrowed + moduleFee; // Module forces user to escrow moduleFee, even when escrowed == 0
        if (toEscrow + instant != 0) {
            if (toEscrow > 0) {
                if (currency == address(0)) {
                    if (msg.value < toEscrow)
                        // User must send sufficient value ahead of time
                        revert InsufficientValue(toEscrow, msg.value);
                } else {
                    // User must approve sufficient value ahead of time
                    IERC20(currency).safeTransferFrom(
                        msg.sender,
                        address(this),
                        toEscrow
                    );
                }
            }

            if (instant > 0) {
                if (currency == address(0)) {
                    if (msg.value != instant + toEscrow)
                        // need to subtract toEscrow from msg.value
                        revert InsufficientValue(instant + toEscrow, msg.value);
                    (bool sent, ) = payer.call{value: instant}("");
                    if (!sent) revert SendFailed();
                } else {
                    IERC20(currency).safeTransferFrom(
                        msg.sender,
                        payer,
                        instant
                    );
                }
            }

            _moduleRevenue[module][currency] += moduleFee;
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
            from, // TODO Might not be needed
            to,
            notaId,
            nota,
            moduleTransferData
        );

        // Fee taking and escrowing
        if (nota.escrowed > 0) {
            // Can't take from 0 escrow
            _notas[notaId].escrowed -= moduleFee;
            _moduleRevenue[nota.module][nota.currency] += moduleFee;
            emit Transferred(
                notaId,
                owner,
                to,
                moduleFee,
                block.timestamp
            );
        } else { // Must be case since fee's can't be taken without an escrow to take from
            emit Transferred(notaId, owner, to, 0, block.timestamp);
        }
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
/**
    function burn(uint256 notaId) public virtual {
        Nota storage nota = _notas[notaId];
        uint256 moduleFee = INotaModule(nota.module).processBurn(
            msg.sender,
            ownerOf(notaId),
            to,
            amount,
            notaId,
            nota,
            cashData
        );

        _burn(notaId);
    }
}
*/