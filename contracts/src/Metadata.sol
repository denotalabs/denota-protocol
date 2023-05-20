// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import {Base64Encoding} from "./Base64Encoding.sol";

// QUESTION: should factory set the BaseURI? What about the docHash?
/// Anyone can issue an
contract Metadata is ERC721, Base64Encoding {
    struct Nota {
        uint256 createdAt;
        address creator;
        string docHash;
        string imageURI;
    }

    mapping(uint256 => Nota) public notaInfo;
    uint256 private _totalSupply;

    constructor() ERC721("denota", "NOTA") {}

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        address owner,
        string calldata metadata,
        string calldata imageURI
    ) public payable returns (uint256) {
        _mint(owner, _totalSupply);
        notaInfo[_totalSupply] = Nota(
            block.timestamp,
            msg.sender,
            metadata,
            imageURI
        );
        unchecked {
            return _totalSupply++;
        }
    }

    function tokenURI(
        uint256 notaId
    ) public view override isMinted(notaId) returns (string memory) {
        Nota memory nota = notaInfo[notaId];
        return
            _buildMetadata(
                itoa(nota.createdAt),
                nota.creator,
                nota.docHash,
                nota.imageURI
            );
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/
    function _buildMetadata(
        string memory createdAt,
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
        address[] calldata owners,
        string[] calldata metadata,
        string[] calldata imageURI
    ) public payable returns (uint256[] memory notaIds) {
        uint256 numWrites = owners.length;

        require(
            numWrites == owners.length &&
                numWrites == metadata.length &&
                numWrites == imageURI.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numWrites; i++) {
            notaIds[i] = write(owners[i], metadata[i], imageURI[i]);
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
    function notaCreatedAt(uint256 notaId) public view returns (uint256) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].createdAt;
    }

    function notaCreator(uint256 notaId) public view returns (address) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].createdAt;
    }

    function notaDocHash(uint256 notaId) public view returns (string memory) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].docHas;
    }

    function notaImageURI(uint256 notaId) public view returns (string memory) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].imageURI;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

/// QUESTION: should the writer just be able to specify?
contract InstantMetadataTo is ERC721, Base64Encoding {
    using SafeERC20 for IERC20;
    struct Nota {
        uint256 createdAt;
        uint256 amount;
        address sender;
        address currency;
        string docHash;
        string imageURI;
    }

    mapping(uint256 => Nota) public notaInfo;
    uint256 private _totalSupply;

    modifier isMinted(uint256 cheqId) {
        if (cheqId >= _totalSupply) revert NotMinted();
        _;
    }

    constructor() ERC721("denota", "NOTA") {}

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        address owner,
        address currency,
        uint256 amount,
        string calldata metadata,
        string calldata imageURI
    ) public payable returns (uint256) {
        // Forward tokens
        if (currency == address(0)) {
            if (msg.value != amount)
                revert InsufficientValue(amount, msg.value);
            (bool sent, ) = owner.call{value: amount}("");
            if (!sent) revert SendFailed();
        } else {
            IERC20(currency).safeTransferFrom(_msgSender(), owner, amount);
        }

        _mint(owner, _totalSupply);
        notaInfo[_totalSupply] = Nota(
            block.timestamp,
            amount,
            msg.sender,
            currency,
            metadata,
            imageURI
        );
        unchecked {
            return _totalSupply++;
        }
    }

    function tokenURI(
        uint256 cheqId
    ) public view override isMinted(cheqId) returns (string memory) {
        Nota memory nota = notaInfo[notaId];
        return
            _buildMetadata(
                itoa(nota.createdAt),
                itoa(nota.amount),
                nota.sender,
                nota.currency,
                nota.docHash,
                nota.imageURI
            );
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/

    function _buildMetadata(
        string memory createdAt,
        string memory amount,
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
                                '},{"trait_type":"Amount","value":"',
                                amount,
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
        address[] calldata owners,
        string[] calldata metadata,
        string[] calldata imageURI
    ) public payable returns (uint256[] memory notaIds) {
        uint256 numWrites = owners.length;

        require(
            numWrites == owners.length &&
                numWrites == metadata.length &&
                numWrites == imageURI.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numWrites; i++) {
            notaIds[i] = write(owners[i], metadata[i], imageURI[i]);
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
    function notaCreatedAt(uint256 notaId) public view returns (uint256) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].createdAt;
    }

    function notaCreator(uint256 notaId) public view returns (address) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].createdAt;
    }

    function notaDocHash(uint256 notaId) public view returns (string memory) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].docHas;
    }

    function notaImageURI(uint256 notaId) public view returns (string memory) {
        if (notaId >= _totalSupply) revert NotMinted();
        return notaInfo[notaId].imageURI;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

/// Let sender keep the Nota
// contract InstantMetadataFrom is ERC721, Base64Encoding {
//     using SafeERC20 for IERC20;
//     struct Nota {
//         uint256 createdAt;
//         uint256 amount;
//         address sender;
//         address currency;
//         string docHash;
//         string imageURI;
//     }

//     mapping(uint256 => Nota) public notaInfo;
//     uint256 private _totalSupply;

//     modifier isMinted(uint256 cheqId) {
//         if (cheqId >= _totalSupply) revert NotMinted();
//         _;
//     }

//     constructor() ERC721("denota", "NOTA") {}

//     /*/////////////////////// WTFCAT ////////////////////////////*/
//     function write(
//         address owner,
//         address currency,
//         uint256 amount,
//         string calldata metadata,
//         string calldata imageURI
//     ) public payable returns (uint256) {
//         // Forward tokens
//         if (currency == address(0)) {
//             if (msg.value != amount)
//                 revert InsufficientValue(amount, msg.value);
//             (bool sent, ) = owner.call{value: amount}("");
//             if (!sent) revert SendFailed();
//         } else {
//             IERC20(currency).safeTransferFrom(_msgSender(), owner, amount);
//         }

//         _mint(owner, _totalSupply);
//         notaInfo[_totalSupply] = Nota(
//             block.timestamp,
//             amount,
//             msg.sender,
//             currency,
//             metadata,
//             imageURI
//         );
//         unchecked {
//             return _totalSupply++;
//         }
//     }

//     function tokenURI(
//         uint256 cheqId
//     ) public view override isMinted(cheqId) returns (string memory) {
//         Nota memory nota = notaInfo[notaId];
//         return
//             _buildMetadata(
//                 itoa(nota.createdAt),
//                 itoa(nota.amount),
//                 nota.sender,
//                 nota.currency,
//                 nota.docHash,
//                 nota.imageURI
//             );
//     }

//     /*///////////////////// URI FUNCTIONS ///////////////////////*/

//     function _buildMetadata(
//         string memory createdAt,
//         string memory amount,
//         address creator,
//         string memory docHash,
//         string memory imageURI
//     ) internal pure returns (string memory) {
//         return
//             string(
//                 abi.encodePacked(
//                     "data:application/json;base64,",
//                     encode(
//                         bytes(
//                             abi.encodePacked(
//                                 '{"attributes":[{"trait_type":"CreatedAt","value":"',
//                                 createdAt,
//                                 '},{"trait_type":"Creator","value":"',
//                                 creator,
//                                 '},{"trait_type":"Amount","value":"',
//                                 amount,
//                                 '"}]',
//                                 '",{"image_data":',
//                                 imageURI,
//                                 '},{"external_url":',
//                                 docHash,
//                                 '"}'
//                             )
//                         )
//                     )
//                 )
//             );
//     }

//     /*///////////////////// BATCH FUNCTIONS ///////////////////////*/

//     function writeBatch(
//         address[] calldata owners,
//         string[] calldata metadata,
//         string[] calldata imageURI
//     ) public payable returns (uint256[] memory notaIds) {
//         uint256 numWrites = owners.length;

//         require(
//             numWrites == owners.length &&
//                 numWrites == metadata.length &&
//                 numWrites == imageURI.length,
//             "Input arrays must have the same length"
//         );

//         for (uint256 i = 0; i < numWrites; i++) {
//             notaIds[i] = write(owners[i], metadata[i], imageURI[i]);
//         }
//     }

//     function transferFromBatch(
//         address[] calldata froms,
//         address[] calldata tos,
//         uint256[] calldata notaIds
//     ) public {
//         uint256 numTransfers = froms.length;

//         require(
//             numTransfers == tos.length && numTransfers == notaIds.length,
//             "Input arrays must have the same length"
//         );

//         for (uint256 i = 0; i < numTransfers; i++) {
//             transferFrom(froms[i], tos[i], notaIds[i]);
//         }
//     }

//     function approveBatch(
//         address[] memory tos,
//         uint256[] memory notaIds
//     ) public {
//         uint256 numApprovals = tos.length;

//         require(
//             numApprovals == notaIds.length,
//             "Input arrays must have the same length"
//         );

//         for (uint256 i = 0; i < numApprovals; i++) {
//             approve(tos[i], notaIds[i]);
//         }
//     }

//     /*///////////////////////// VIEW ////////////////////////////*/
//     function notaCreatedAt(uint256 notaId) public view returns (uint256) {
//         if (notaId >= _totalSupply) revert NotMinted();
//         return notaInfo[notaId].createdAt;
//     }

//     function notaCreator(uint256 notaId) public view returns (address) {
//         if (notaId >= _totalSupply) revert NotMinted();
//         return notaInfo[notaId].createdAt;
//     }

//     function notaDocHash(uint256 notaId) public view returns (string memory) {
//         if (notaId >= _totalSupply) revert NotMinted();
//         return notaInfo[notaId].docHas;
//     }

//     function notaImageURI(uint256 notaId) public view returns (string memory) {
//         if (notaId >= _totalSupply) revert NotMinted();
//         return notaInfo[notaId].imageURI;
//     }

//     function totalSupply() public view returns (uint256) {
//         return _totalSupply;
//     }
// }

contract MetadataFactory {
    mapping(address => address) public metadata;
    address[] public metadatas;

    constructor() {}

    function deploy() external {
        Registrar registrar = new Metadata(); // TODO
        currencyTimelock[msg.sender] = address(registrar);
        currencyTimelocks.push(address(registrar));
    }
}
