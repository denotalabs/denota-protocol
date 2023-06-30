// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/Strings.sol";
import {INotaModule} from "./interfaces/INotaModule.sol";
import {INotaRegistrar} from "./interfaces/INotaRegistrar.sol";
import {NotaEncoding} from "./libraries/Base64Encoding.sol";
import {DataTypes} from "./libraries/DataTypes.sol";

 /// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}
contract ERC4906 is ERC721, IERC4906 {

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}

/**
 * @title  The Nota Payment Registrar
 * @notice The main contract where users can WTFCA notas
 * @author Alejandro Almaraz
 * @dev    Tracks ownership of notas' data + escrow, whitelists tokens/modules, and collects revenue.
 */
contract NotaRegistrar is
    Ownable,
    ERC4906,
    INotaRegistrar,
    NotaEncoding
{
    using SafeERC20 for IERC20;
    using Strings for address;
    mapping(address => mapping(address => uint256)) internal _moduleRevenue; 
    mapping(address => uint256) internal _protocolRevenue; 
    mapping(uint256 => DataTypes.Nota) private _notaInfo;
    uint256 private _totalSupply;
    event Written(
        address indexed caller,
        uint256 notaId,
        address indexed owner, // Question is this needed considering ERC721 _mint() emits owner `from` address(0) `to` owner?
        uint256 instant,
        address indexed currency,
        uint256 escrowed,
        uint256 createdAt,
        uint256 moduleFee,
        address module,
        bytes moduleData
    );
    // Not used
    event Transferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 moduleFee,
        uint256 timestamp
    );
    event Funded(
        address indexed funder,
        uint256 indexed notaId,
        uint256 amount,
        uint256 instant,
        bytes indexed fundData,
        uint256 moduleFee,
        uint256 timestamp
    );
    event Cashed(
        address indexed casher,
        uint256 indexed notaId,
        address to,
        uint256 amount,
        bytes indexed cashData,
        uint256 moduleFee,
        uint256 timestamp
    );

    error SendFailed();
    error SelfApproval();
    error NotMinted();
    error InvalidWrite(address, address);
    error InsufficientValue(uint256, uint256);
    error InsufficientEscrow(uint256, uint256);

    modifier isMinted(uint256 notaId) {
        if (notaId >= _totalSupply) revert NotMinted();
        _;
    }

    constructor() ERC4906("denota", "NOTA") {}

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        address currency,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address module,
        bytes calldata moduleWriteData
    ) public payable returns (uint256) {
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
        _notaInfo[_totalSupply] = DataTypes.Nota(
            escrowed,
            block.timestamp,
            currency,
            module
        );

        emit Written(
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
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 notaId
    ) public override(ERC721, IERC721, INotaRegistrar) isMinted(notaId) {
        _transferHookTakeFee(from, to, notaId, abi.encode(""));
        _transfer(from, to, notaId);
        // emit MetadataUpdate(notaId);
    }

    function fund(
        uint256 notaId,
        uint256 amount,
        uint256 instant,
        bytes calldata fundData
    ) public payable isMinted(notaId) {
        DataTypes.Nota memory nota = _notaInfo[notaId]; // TODO module MUST check that token exists
        address owner = ownerOf(notaId); // Is used twice

        // Module hook
        uint256 moduleFee = INotaModule(nota.module).processFund(
            _msgSender(),
            owner,
            amount,
            instant,
            notaId,
            nota,
            fundData
        );

        // Fee taking and escrow
        _transferTokens(
            amount,
            instant,
            nota.currency,
            owner,
            moduleFee,
            nota.module
        );

        _notaInfo[notaId].escrowed += amount; // Question: is this cheaper than testing if (amount == 0)?
        // nota.escrowed += amount;

        emit Funded(
            _msgSender(),
            notaId,
            amount,
            instant,
            fundData,
            moduleFee,
            block.timestamp
        );
        // emit MetadataUpdate(notaId);
    }

    function cash(
        uint256 notaId,
        uint256 amount,
        address to,
        bytes calldata cashData
    ) public payable isMinted(notaId) {
        DataTypes.Nota memory nota = _notaInfo[notaId];

        // Module Hook
        uint256 moduleFee = INotaModule(nota.module).processCash(
            _msgSender(),
            ownerOf(notaId),
            to,
            amount,
            notaId,
            nota,
            cashData
        );

        // Fee taking
        uint256 totalAmount = amount + moduleFee;

        // Un-escrowing
        if (totalAmount > nota.escrowed)
            revert InsufficientEscrow(totalAmount, nota.escrowed);
        unchecked {
            _notaInfo[notaId].escrowed -= totalAmount;
        } // Could this just underflow and revert anyway (save gas)?
        if (nota.currency == address(0)) {
            (bool sent, ) = to.call{value: amount}("");
            if (!sent) revert SendFailed();
        } else {
            IERC20(nota.currency).safeTransfer(to, amount);
        }
        _moduleRevenue[nota.module][nota.currency] += moduleFee;

        emit Cashed(
            _msgSender(),
            notaId,
            to,
            amount,
            cashData,
            moduleFee,
            block.timestamp
        );
    }

    function approve(
        address to,
        uint256 notaId
    ) public override(ERC721, IERC721, INotaRegistrar) isMinted(notaId) {
        if (to == _msgSender()) revert SelfApproval();

        // Module hook
        DataTypes.Nota memory nota = _notaInfo[notaId];
        INotaModule(nota.module).processApproval(
            _msgSender(),
            ownerOf(notaId),
            to,
            notaId,
            nota,
            ""
        );

        // Approve
        _approve(to, notaId);
        // emit MetadataUpdate(notaId);
    }
    
    function tokenURI(
        uint256 notaId
    ) public view override isMinted(notaId) returns (string memory) {
        (string memory moduleAttributes, string memory moduleKeys) = INotaModule(_notaInfo[notaId].module)
            .processTokenURI(notaId);

        return
            toJSON(
                Strings.toHexString(uint256(uint160(_notaInfo[notaId].currency)), 20),
                itoa(_notaInfo[notaId].escrowed),
                itoa(_notaInfo[notaId].createdAt),
                Strings.toHexString(uint256(uint160(_notaInfo[notaId].module)), 20),
                moduleAttributes,
                moduleKeys
            );
    }

    /*///////////////////// BATCH FUNCTIONS ///////////////////////*/

    function writeBatch(
        address[] calldata currencies,
        uint256[] calldata escrowedAmounts,
        uint256[] calldata instantAmounts,
        address[] calldata owners,
        address[] calldata modules,
        bytes[] calldata moduleWriteDataList
    ) public payable returns (uint256[] memory notaIds) {
        uint256 numWrites = currencies.length;

        require(
            numWrites == escrowedAmounts.length &&
                numWrites == instantAmounts.length &&
                numWrites == owners.length &&
                numWrites == modules.length &&
                numWrites == moduleWriteDataList.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numWrites; i++) {
            notaIds[i] = write(
                currencies[i],
                escrowedAmounts[i],
                instantAmounts[i],
                owners[i],
                modules[i],
                moduleWriteDataList[i]
            );
        }
    }

    function transferFromBatch(
        address[] calldata froms,
        address[] calldata tos,
        uint256[] calldata notaIds
    ) public {
        uint256 numTransfers = froms.length;

        require(
            numTransfers == tos.length && numTransfers == notaIds.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numTransfers; i++) {
            transferFrom(froms[i], tos[i], notaIds[i]);
        }
    }

    function fundBatch(
        uint256[] calldata notaIds,
        uint256[] calldata amounts,
        uint256[] calldata instants,
        bytes[] calldata fundDataList
    ) public payable {
        uint256 numFunds = notaIds.length;

        require(
            numFunds == amounts.length &&
                numFunds == instants.length &&
                numFunds == fundDataList.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numFunds; i++) {
            fund(notaIds[i], amounts[i], instants[i], fundDataList[i]);
        }
    }

    function cashBatch(
        uint256[] calldata notaIds,
        uint256[] calldata amounts,
        address[] calldata tos,
        bytes[] calldata cashDataList
    ) public payable {
        uint256 numCash = notaIds.length;

        require(
            numCash == amounts.length &&
                numCash == tos.length &&
                numCash == cashDataList.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numCash; i++) {
            cash(notaIds[i], amounts[i], tos[i], cashDataList[i]);
        }
    }

    function approveBatch(
        address[] memory tos,
        uint256[] memory notaIds
    ) public {
        uint256 numApprovals = tos.length;

        require(
            numApprovals == notaIds.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numApprovals; i++) {
            approve(tos[i], notaIds[i]);
        }
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
        uint256 notaId,
        bytes memory moduleTransferData
    ) internal {
        if (moduleTransferData.length == 0)
            moduleTransferData = abi.encode(owner());
        address owner = ownerOf(notaId); // require(from == owner,  "") ?
        DataTypes.Nota memory nota = _notaInfo[notaId]; // Better to assign than to index?
        // No approveOrOwner check, allow module to decide

        // Module hook
        uint256 moduleFee = INotaModule(nota.module).processTransfer(
            _msgSender(),
            getApproved(notaId),
            owner,
            from, // TODO Might not be needed
            to,
            notaId,
            nota,
            moduleTransferData
        );

        // Fee taking and escrowing
        if (_notaInfo[notaId].escrowed > 0) {
            // Can't take from 0 escrow
            _notaInfo[notaId].escrowed -= moduleFee;
            _moduleRevenue[nota.module][nota.currency] += moduleFee;
            emit Transferred(
                notaId,
                owner,
                to,
                moduleFee,
                block.timestamp
            );
        } else {
            // Must be case since fee's can't be taken without an escrow to take from
            emit Transferred(notaId, owner, to, 0, block.timestamp);
        }
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

    function metadataUpdate(uint256 notaId) external {
        DataTypes.Nota memory nota = _notaInfo[notaId];
        require(_msgSender() == nota.module, "NOT_MODULE");
        emit MetadataUpdate(notaId);
    }

    /*///////////////////////// VIEW ////////////////////////////*/
    function notaInfo(
        uint256 notaId
    ) public view returns (DataTypes.Nota memory) {
        if (notaId >= _totalSupply) revert NotMinted();
        return _notaInfo[notaId];
    }
    function notaEscrowed(uint256 notaId) public view returns (uint256) {
        if (notaId >= _totalSupply) revert NotMinted();
        return _notaInfo[notaId].escrowed;
    }
    function notaCreatedAt(uint256 notaId) public view returns (uint256) {
        if (notaId >= _totalSupply) revert NotMinted();
        return _notaInfo[notaId].createdAt;
    }
    function notaCurrency(uint256 notaId) public view returns (address) {
        if (notaId >= _totalSupply) revert NotMinted();
        return _notaInfo[notaId].currency;
    }
    function notaModule(uint256 notaId) public view returns (address) {
        if (notaId >= _totalSupply) revert NotMinted();
        return _notaInfo[notaId].module;
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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
}

/**
    function burn(uint256 notaId) public virtual {
        DataTypes.Nota storage nota = _notaInfo[notaId];
        uint256 moduleFee = INotaModule(nota.module).processCash(
            _msgSender(),
            ownerOf(notaId),
            to,
            amount,
            notaId,
            nota,
            cashData
        );

        _burn(notaId);
        emit Transfer(ownerOf(notaId), address(0), notaId);
    }

    function burnBatch(
        address[] memory tos,
        uint256[] memory notaIds
    ) public {
        uint256 numBurns = tos.length;

        require(
            numBurns == notaIds.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numBurns; i++) {
            burn(tos[i], notaIds[i]);
        }
    }
*/