// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/Base64.sol";

// Sender either releases to the recipient or back to themselves
contract ReverseRelease is ERC721, Base64 {
    using SafeERC20 for IERC20;

    struct Nota {
        uint256 escrowed;
        uint256 maturationDate;
        uint256 createdAt;
        string docHash;
        string imageURI;
    }

    address public currency;
    mapping(uint256 => Nota) public notaInfo;
    uint256 private _totalSupply;

    error InsufficientValue(uint256, uint256);
    event Timelocked(
        uint256 indexed notaId,
        uint256 escrowed,
        uint256 maturationDate,
        uint256 createdAt
    );

    constructor(address _currency) ERC721("denota", "NOTA") {
        currency = _currency;
    }

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        uint256 escrowed,
        uint256 maturationDate,
        address owner,
        string calldata docHash,
        string calldata imageURI
    ) public payable returns (uint256) {
        require(maturationDate > block.timestamp, "INVALID_DATE");
        if (escrowed > 0) {
            if (currency == address(0)) {
                if (msg.value < escrowed)
                    revert InsufficientValue(escrowed, msg.value);
            } else {
                IERC20(currency).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    escrowed
                );
            }
        }

        _mint(owner, _totalSupply);
        notaInfo[_totalSupply] = Nota(
            escrowed,
            maturationDate,
            block.timestamp,
            docHash,
            imageURI
        );

        emit Timelocked(
            _totalSupply,
            escrowed,
            maturationDate,
            block.timestamp
        );
        unchecked {
            return _totalSupply++;
        }
    }

    function tokenURI(
        uint256 notaId
    ) public view override returns (string memory) {
        _requireMinted(notaId);
        Nota memory nota = notaInfo[notaId];
        return
            _buildMetadata(
                itoa(nota.createdAt),
                itoa(nota.escrowed),
                itoa(nota.maturationDate),
                currency, // Is this needed since the contract address implies this?
                nota.creator,
                nota.docHash,
                nota.imageURI
            );
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/
    function _buildMetadata(
        string memory createdAt,
        string memory escrowed,
        string memory maturationDate,
        address creator,
        string memory docHash,
        string memory imageURI
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"attributes":[{"trait_type":"CreatedAt","value":"',
                                createdAt,
                                '},{"trait_type":"Creator","value":"',
                                creator,
                                '},{"trait_type":"Escrowed","value":"',
                                escrowed,
                                '},{"trait_type":"Maturation Date","value":"',
                                maturationDate,
                                '"}]',
                                '",{"image_data":',
                                imageURI,
                                '},{"external_url":',
                                docHash,
                                '"}'
                            )
                        )
                    )
                )
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

    /*///////////////////////// VIEW ////////////////////////////*/
    function notaInfo(
        uint256 notaId
    ) public view returns (DataTypes.Nota memory) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId];
    }

    function notaEscrowed(uint256 notaId) public view returns (uint256) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].escrowed;
    }

    function notaMaturationDate(uint256 notaId) public view returns (uint256) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].maturationDate;
    }

    function notaCreatedAt(uint256 notaId) public view returns (uint256) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].createdAt;
    }

    /**
        uint256 maturationDate;
        uint256 createdAt;
        string docHash;
        string imageURI;
 */

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

contract ReverseReleaseTimelock is ERC721, Base64 {}

/// The contract has a single person that can reverse all notas
contract ReverseReleaseStatic is ERC721, Base64 {

}

/// Sender can set who is the reversing party
contract ReverseReleaseSettable is ERC721, Base64 {

}

/// The contract has a single person that can reverse all notas, single settlement time
contract ReverseReleaseStaticTimelock is ERC721, Base64 {

}

/// Sender can set who is the reversing party, single settlement time
contract ReverseReleaseSettableTimelock is ERC721, Base64 {

}
// contract Factory {
//     mapping(address => address) public currencyTimelock;
//     address[] public currencyTimelocks;

//     constructor() {}

//     function deploy(address currency) external {
//         Registrar registrar = new TimelockRegistrar(currency); // TODO check that this succeeds
//         currencyTimelock[currency] = address(registrar);
//         currencyTimelocks.push(address(registrar));
//     }
// }
