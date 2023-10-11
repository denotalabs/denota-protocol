// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {ERC721} from "./ERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import {Events} from "./libraries/Events.sol";
import {RegistrarGov} from "./RegistrarGov.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {INotaModule} from "./interfaces/INotaModule.sol";
import {INotaRegistrar} from "./interfaces/INotaRegistrar.sol";
import {NotaBase64Encoding} from "./libraries/NotaBase64Encoding.sol";

/**
     Ownable  IRegistrarGov
          \      /
        RegistrarGov INotaRegistrar ERC721
                    \      |       /
                      NotaRegistrar
 */

/**
 * @title  The Nota Payment Registrar
 * @notice The main contract where users can WTFCA cheqs
 * @author Alejandro Almaraz
 * @dev    Tracks ownership of cheqs' data + escrow, whitelists tokens/modules, and collects revenue.
 */
contract NotaRegistrar is
    ERC721,
    RegistrarGov,
    INotaRegistrar,
    NotaBase64Encoding
{
    using SafeERC20 for IERC20;

    mapping(uint256 => DataTypes.Nota) private _notaInfo;
    uint256 private _totalSupply;

    error SendFailed();
    error InvalidWrite(address, address);
    error InsufficientValue(uint256, uint256);
    error InsufficientEscrow(uint256, uint256);

    constructor() ERC721("denota", "NOTA") {}

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        address currency,
        uint256 escrowed,
        uint256 instant, // if nonFungible is supported make sure this can't be used (or use native)
        address owner,
        address module,
        bytes calldata moduleWriteData
    ) public payable returns (uint256) {
        // require(msg.value >= _writeFlatFee, "INSUF_FEE"); // IDEA: discourages spamming of 0 value cheqs
        if (!validWrite(module, currency))
            revert InvalidWrite(module, currency); // Module+token whitelist check

        // Module hook (updates its storage, gets the fee)
        uint256 moduleFee = INotaModule(module).processWrite(
            _msgSender(),
            owner,
            _totalSupply,
            currency,
            escrowed,
            instant,
            moduleWriteData
        );

        _transferTokens(escrowed, instant, currency, owner, moduleFee, module);

        _mint(owner, _totalSupply);
        _notaInfo[_totalSupply].currency = currency;
        _notaInfo[_totalSupply].escrowed = escrowed;
        _notaInfo[_totalSupply].createdAt = block.timestamp;
        _notaInfo[_totalSupply].module = module;

        emit Events.Written(
            _msgSender(),
            _totalSupply,
            owner,
            instant,
            currency,
            escrowed,
            block.timestamp,
            moduleFee,
            module,
            moduleWriteData
        );
        unchecked {
            return _totalSupply++;
        } // NOTE: Will this ever overflow?
    }

    function transferFrom(
        address from,
        address to,
        uint256 cheqId
    ) public override(ERC721, INotaRegistrar) {
        if (cheqId >= _totalSupply) revert NotMinted();
        _transferHookTakeFee(from, to, cheqId, abi.encode(""));
        _transfer(from, to, cheqId);
    }

    function fund(
        uint256 cheqId,
        uint256 amount,
        uint256 instant,
        bytes calldata fundData
    ) external payable {
        if (cheqId >= _totalSupply) revert NotMinted();
        DataTypes.Nota storage cheq = _notaInfo[cheqId]; // TODO module MUST check that token exists
        address owner = ownerOf(cheqId); // Is used twice

        // Module hook
        uint256 moduleFee = INotaModule(cheq.module).processFund(
            _msgSender(),
            owner,
            amount,
            instant,
            cheqId,
            cheq,
            fundData
        );

        // Fee taking and escrow
        _transferTokens(
            amount,
            instant,
            cheq.currency,
            owner,
            moduleFee,
            cheq.module
        );

        _notaInfo[cheqId].escrowed += amount; // Question: is this cheaper than testing if amount == 0?

        emit Events.Funded(
            _msgSender(),
            cheqId,
            amount,
            instant,
            fundData,
            moduleFee,
            block.timestamp
        );
    }

    function cash(
        uint256 cheqId,
        uint256 amount,
        address to,
        bytes calldata cashData
    ) external payable {
        if (cheqId >= _totalSupply) revert NotMinted();
        DataTypes.Nota storage cheq = _notaInfo[cheqId];

        // Module Hook
        uint256 moduleFee = INotaModule(cheq.module).processCash(
            _msgSender(),
            ownerOf(cheqId),
            to,
            amount,
            cheqId,
            cheq,
            cashData
        );

        // Fee taking
        uint256 totalAmount = amount + moduleFee;

        // Un-escrowing
        if (totalAmount > cheq.escrowed)
            revert InsufficientEscrow(totalAmount, cheq.escrowed);
        unchecked {
            cheq.escrowed -= totalAmount;
        } // Could this just underflow and revert anyway (save gas)?
        if (cheq.currency == address(0)) {
            (bool sent, ) = to.call{value: amount}("");
            if (!sent) revert SendFailed();
        } else {
            IERC20(cheq.currency).safeTransfer(to, amount);
        }
        _moduleRevenue[cheq.module][cheq.currency] += moduleFee;

        emit Events.Cashed(
            _msgSender(),
            cheqId,
            to,
            amount,
            cashData,
            moduleFee,
            block.timestamp
        );
    }

    function approve(
        address to,
        uint256 cheqId
    ) public override(ERC721, INotaRegistrar) {
        if (cheqId >= _totalSupply) revert NotMinted();
        if (to == _msgSender()) revert SelfApproval();

        // Module hook
        DataTypes.Nota memory cheq = _notaInfo[cheqId];
        INotaModule(cheq.module).processApproval(
            _msgSender(),
            ownerOf(cheqId),
            to,
            cheqId,
            cheq,
            ""
        );

        // Approve
        _approve(to, cheqId);
    }

    function tokenURI(
        uint256 cheqId
    ) public view override returns (string memory) {
        if (cheqId >= _totalSupply) revert NotMinted();

        string memory _tokenData = INotaModule(_notaInfo[cheqId].module)
            .processTokenURI(cheqId);

        return
            buildMetadata(
                _tokenName[_notaInfo[cheqId].currency],
                itoa(_notaInfo[cheqId].escrowed),
                // itoa(_notaInfo[_cheqId].createdAt),
                _moduleName[_notaInfo[cheqId].module],
                _tokenData
            );
    }

    /*//////////////////////// HELPERS ///////////////////////////*/
    function _transferTokens(
        uint256 escrowed,
        uint256 instant,
        address currency,
        address owner,
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
                        _msgSender(),
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
                    (bool sent, ) = owner.call{value: instant}("");
                    if (!sent) revert SendFailed();
                } else {
                    IERC20(currency).safeTransferFrom(
                        _msgSender(),
                        owner,
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
        uint256 cheqId,
        bytes memory moduleTransferData
    ) internal {
        if (moduleTransferData.length == 0)
            moduleTransferData = abi.encode(owner());
        address owner = ownerOf(cheqId); // require(from == owner,  "") ?
        DataTypes.Nota storage cheq = _notaInfo[cheqId]; // Better to assign than to index?
        // No approveOrOwner check, allow module to decide

        // Module hook
        uint256 moduleFee = INotaModule(cheq.module).processTransfer(
            _msgSender(),
            getApproved(cheqId),
            owner,
            from, // TODO Might not be needed
            to,
            cheqId,
            cheq.currency,
            cheq.escrowed,
            cheq.createdAt,
            moduleTransferData
        );

        // Fee taking and escrowing
        if (cheq.escrowed > 0) {
            // Can't take from 0 escrow
            cheq.escrowed = cheq.escrowed - moduleFee;
            _moduleRevenue[cheq.module][cheq.currency] += moduleFee;
            emit Events.Transferred(
                cheqId,
                owner,
                to,
                moduleFee,
                block.timestamp
            );
        } else {
            // Must be case since fee's can't be taken without an escrow to take from
            emit Events.Transferred(cheqId, owner, to, 0, block.timestamp);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 cheqId,
        bytes memory moduleTransferData
    ) public override(ERC721, INotaRegistrar) {
        _transferHookTakeFee(from, to, cheqId, moduleTransferData);
        _safeTransfer(from, to, cheqId, moduleTransferData);
    }

    /*///////////////////////// VIEW ////////////////////////////*/
    function cheqInfo(
        uint256 cheqId
    ) public view returns (DataTypes.Nota memory) {
        if (cheqId >= _totalSupply) revert NotMinted();
        return _notaInfo[cheqId];
    }

    function cheqCurrency(uint256 cheqId) public view returns (address) {
        if (cheqId >= _totalSupply) revert NotMinted();
        return _notaInfo[cheqId].currency;
    }

    function cheqEscrowed(uint256 cheqId) public view returns (uint256) {
        if (cheqId >= _totalSupply) revert NotMinted();
        return _notaInfo[cheqId].escrowed;
    }

    function cheqModule(uint256 cheqId) public view returns (address) {
        if (cheqId >= _totalSupply) revert NotMinted();
        return _notaInfo[cheqId].module;
    }

    function cheqCreatedAt(uint256 cheqId) public view returns (uint256) {
        if (cheqId >= _totalSupply) revert NotMinted();
        return _notaInfo[cheqId].createdAt;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}
