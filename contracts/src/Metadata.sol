// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/utils/Strings.sol";
import {Base64Encoding} from "./Base64Encoding.sol";

// TODO how to have onion of tokenURI metadata? Maybe each contract has it's own JSON key (attributes, image_data, external_url, ect)?
// TODO add front-end operator fees
// TODO add Ownable versions (onlyOwner can mint)
contract MetadataOnly is ERC721, Base64Encoding {
    struct Nota {
        // uint256 createdAt; // Question: is this needed?
        // address creator;  // Question: is this needed?
        string docHash;
        string imageURI;
    }

    string public baseImageURI;
    string public baseDocHashURI;
    mapping(uint256 => Nota) public notaInfo;
    uint256 private _totalSupply;

    constructor(
        string memory _baseImageURI,
        string memory _baseDocHashURI
    ) ERC721("denota", "NOTA") {
        baseImageURI = _baseImageURI;
        baseDocHashURI = _baseDocHashURI;
    }

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        address owner,
        string calldata imageURI,
        string calldata docHashURI
    ) public payable returns (uint256) {
        _mint(owner, _totalSupply);
        notaInfo[_totalSupply] = Nota(
            // block.timestamp,
            // msg.sender,
            imageURI,
            docHashURI
        );
        unchecked {
            return _totalSupply++;
        }
    }

    function tokenURI(
        uint256 notaId
    ) public view override returns (string memory) {
        require(_exists(notaId), "");
        Nota memory nota = notaInfo[notaId];
        return
            _buildMetadata(
                // itoa(nota.createdAt),
                // nota.creator,
                nota.docHash,
                nota.imageURI
            );
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/
    function _buildMetadata(
        // string memory createdAt,
        // address creator,
        string memory docHash,
        string memory imageURI
    ) internal view returns (string memory) {
        // TODO how to switch based on whether the URIs are empty
        // TODO if the currency is a NFT

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked(
                                // '{"attributes":[{"trait_type":"CreatedAt","value":"',
                                // createdAt,
                                // '},{"trait_type":"Creator","value":"',
                                // creator,
                                // '"}]',
                                // '",{"image_data":',
                                '{"image_data":"',
                                baseImageURI,
                                imageURI,
                                '","external_url":"',
                                baseDocHashURI,
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
    // function notaCreatedAt(uint256 notaId) public view returns (uint256) {
    //     require(_exists(notaId));
    //     return notaInfo[notaId].createdAt;
    // }

    // function notaCreator(uint256 notaId) public view returns (address) {
    //     require(_exists(notaId));
    //     return notaInfo[notaId].creator;
    // }

    function notaDocHash(uint256 notaId) public view returns (string memory) {
        require(_exists(notaId));
        return notaInfo[notaId].docHash;
    }

    function notaImageURI(uint256 notaId) public view returns (string memory) {
        require(_exists(notaId));
        return notaInfo[notaId].imageURI;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

contract MetadataOnlyFactory {
    mapping(bytes32 => address) public metadata;
    address[] public metadatas;

    constructor() {}

    function deploy(
        string memory _baseImageURI,
        string memory _baseDocHashURI
    ) external returns (address) {
        bytes32 salt = keccak256(
            abi.encodePacked(_baseImageURI, _baseDocHashURI)
        );
        require(metadata[salt] == address(0), "EXISTS");
        MetadataOnly registrar = new MetadataOnly(
            _baseImageURI,
            _baseDocHashURI
        );
        address newContract = address(registrar);
        metadata[salt] = newContract;
        metadatas.push(newContract);
        return newContract;
    }
}

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";

// QUESTION: Should writer specify who the value is going to vs the Nota?
contract InstantMetadataTo is ERC721, Base64Encoding {
    using SafeERC20 for IERC20;
    using Strings for string;

    struct Nota {
        uint256 amount;
        address currency;
        string docHash;
        string imageURI;
    }
    string public baseImageURI;
    string public baseDocHashURI;
    mapping(uint256 => Nota) public notaInfo;
    uint256 private _totalSupply;
    error SendFailed();
    error InsufficientValue(uint256, uint256);

    constructor(
        string memory _baseImageURI,
        string memory _baseDocHashURI
    ) ERC721("denota", "NOTA") {
        baseImageURI = _baseImageURI;
        baseDocHashURI = _baseDocHashURI;
    }

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        address owner,
        address currency,
        uint256 amount,
        string calldata imageURI,
        string calldata docHashURI
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
        notaInfo[_totalSupply] = Nota(amount, currency, imageURI, docHashURI);
        unchecked {
            return _totalSupply++;
        }
    }

    function tokenURI(
        uint256 notaId
    ) public view override returns (string memory) {
        require(_exists(notaId));
        Nota memory nota = notaInfo[notaId];
        return
            _buildMetadata(
                itoa(nota.amount),
                Strings.toHexString(uint160(nota.currency), 20),
                nota.docHash,
                nota.imageURI
            );
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/

    function _buildMetadata(
        string memory amount,
        string memory currency,
        string memory docHash,
        string memory imageURI
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"attributes":[{"trait_type":"Amount","value":"',
                                amount,
                                '"},{"trait_type":"Currency","value":"',
                                currency,
                                '"}],"image_data":"',
                                baseImageURI,
                                imageURI,
                                '","external_url":"',
                                baseDocHashURI,
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
        address[] calldata currencies,
        uint256[] calldata amounts,
        string[] calldata imageURIs,
        string[] calldata docHashURIs
    ) public payable returns (uint256[] memory notaIds) {
        uint256 numWrites = owners.length;

        require(
            numWrites == currencies.length &&
                numWrites == amounts.length &&
                numWrites == imageURIs.length &&
                numWrites == docHashURIs.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < numWrites; i++) {
            notaIds[i] = write(
                owners[i],
                currencies[i],
                amounts[i],
                imageURIs[i],
                docHashURIs[i]
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
    function notaAmount(uint256 notaId) public view returns (uint256) {
        require(_exists(notaId));
        return notaInfo[notaId].amount;
    }

    function notaCurrency(uint256 notaId) public view returns (address) {
        require(_exists(notaId));
        return notaInfo[notaId].currency;
    }

    function notaDocHash(uint256 notaId) public view returns (string memory) {
        require(_exists(notaId));
        return notaInfo[notaId].docHash;
    }

    function notaImageURI(uint256 notaId) public view returns (string memory) {
        require(_exists(notaId));
        return notaInfo[notaId].imageURI;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

contract InstantMetadataToFactory {
    mapping(bytes32 => address) public instantMetadataTo;
    address[] public instantMetadataTos;

    constructor() {}

    function deploy(
        string memory _baseImageURI,
        string memory _baseDocHashURI
    ) external returns (address) {
        bytes32 salt = keccak256(
            abi.encodePacked(_baseImageURI, _baseDocHashURI)
        );
        require(instantMetadataTo[salt] == address(0), "EXISTS");
        InstantMetadataTo registrar = new InstantMetadataTo(
            _baseImageURI,
            _baseDocHashURI
        );
        address newContract = address(registrar);
        instantMetadataTo[salt] = newContract;
        instantMetadataTos.push(newContract);
        return newContract;
    }
}

contract MetadataOnly is ERC721, Base64Encoding {
    struct Nota {
        string docHash;
        string imageURI;
    }
    ERC721 public currency;
    string public baseImageURI;
    string public baseDocHashURI;
    mapping(uint256 => Nota) public notaInfo;
    uint256 private _totalSupply;

    function tokenURI(
        uint256 notaId
    ) public view override returns (string memory) {
        require(_exists(notaId), "");
        Nota memory nota = notaInfo[notaId];
        string memory innerURI = currency.tokenURI(notaId);
        return _buildMetadata(nota.docHash, innerURI);
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/
    function _buildMetadata(
        // string memory createdAt,
        // address creator,
        string memory docHash,
        string memory imageURI
    ) internal view returns (string memory) {
        // TODO how to switch based on whether the URIs are empty
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"image_data":"',
                                imageURI,
                                '","external_url":"',
                                baseDocHashURI,
                                docHash,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}

// // Let sender keep the Nota
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

//     modifier isMinted(uint256 notaId) {
//         if (notaId >= _totalSupply) revert NotMinted();
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
//         uint256 notaId
//     ) public view override isMinted(notaId) returns (string memory) {
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
