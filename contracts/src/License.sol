// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import {Base64Encoding} from "./Base64Encoding.sol";

// Deploy an NFT contract that can act as a license issuer
// IDEA can add bonding curve
// Question: add different currencies here?
contract License is ERC721, Base64Encoding, Ownable {
    struct Nota {
        uint256 createdAt;
        uint expirationTime;
    }
    // todo can do a bonding curve of price.
    address public _currency;
    uint256 public _pricePerSecond; // Price per unit second Question: change to minute or hour?
    // uint256 public maxSeconds; // max seconds
    uint256 private _availableSupply;
    // mapping(address => bool) public acceptedCurrency; // Should just a single currency be used? Simpler
    // mapping(address => uint256) public currencyPrice;
    // uint256 private purchaseRateLimiter;
    uint256 private _totalSupply;
    string public baseURI; // Should this be dynamic or dependant on tokenId?
    mapping(uint256 => Nota) public notaInfo;

    constructor(
        string memory _name,
        string memory _symbol,
        address currency,
        uint256 pricePerSecond,
        uint256 available
    ) ERC721(_name, _symbol) {
        _currency = currency;
        _pricePerSecond = pricePerSecond;
        _availableSupply = available;
    }

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(uint256 _seconds) public payable returns (uint256) {
        _availableSupply -= 1; // Note: should fail on underflow
        uint256 price = _pricePerSecond * _seconds;
        require(IERC20(_currency).transferFrom(msg.sender, owner(), price), ""); // Question: send straight to owner?
        uint256 expirationTime = _pricePerSecond * _seconds;
        _mint(msg.sender, _totalSupply);
        notaInfo[_totalSupply] = Nota(block.timestamp, expirationTime);
        unchecked {
            return _totalSupply++;
        }
    }

    function tokenURI(
        uint256 notaId
    ) public view override returns (string memory) {
        Nota memory nota = notaInfo[notaId];
        string memory imageURI = string(abi.encodePacked(baseURI, notaId));
        return
            _buildMetadata(
                itoa(nota.createdAt),
                itoa(nota.expirationTime),
                imageURI
            );
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/
    function _buildMetadata(
        string memory createdAt,
        string memory expirationTime,
        // string memory docHash,
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
                                '},{"trait_type":"Expiration","value":"',
                                expirationTime,
                                '"}]',
                                '",{"image_data":',
                                imageURI,
                                "'}}"
                                // '},{"external_url":',
                                // docHash,
                                // '"}'
                            )
                        )
                    )
                )
            );
    }

    function setPricePerSecond(uint256 pricePerSecond) external onlyOwner {
        _pricePerSecond = pricePerSecond;
    }

    function setAvailable(uint256 additional) external onlyOwner {
        _availableSupply += additional;
    }

    /*///////////////////// BATCH FUNCTIONS ///////////////////////*/

    // function writeBatch(
    //     address[] calldata owners,
    //     string[] calldata metadata,
    //     string[] calldata imageURI
    // ) public payable returns (uint256[] memory notaIds) {
    //     uint256 numWrites = owners.length;

    //     require(
    //         numWrites == owners.length &&
    //             numWrites == metadata.length &&
    //             numWrites == imageURI.length,
    //         "Input arrays must have the same length"
    //     );

    //     for (uint256 i = 0; i < numWrites; i++) {
    //         notaIds[i] = write(owners[i], metadata[i], imageURI[i]);
    //     }
    // }

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
    //     if (notaId >= _totalSupply) revert NotMinted();
    //     return notaInfo[notaId].createdAt;
    // }

    // function notaCreator(uint256 notaId) public view returns (address) {
    //     if (notaId >= _totalSupply) revert NotMinted();
    //     return notaInfo[notaId].createdAt;
    // }

    // function notaDocHash(uint256 notaId) public view returns (string memory) {
    //     if (notaId >= _totalSupply) revert NotMinted();
    //     return notaInfo[notaId].docHas;
    // }

    // function notaImageURI(uint256 notaId) public view returns (string memory) {
    //     if (notaId >= _totalSupply) revert NotMinted();
    //     return notaInfo[notaId].imageURI;
    // }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

contract LicenseFactory {
    mapping(address => uint256) public userLicenseCount;
    mapping(address => mapping(uint256 => address)) public getLicense;
    address[] public licenses;

    constructor() {}

    function deploy(
        string memory name,
        string memory symbol,
        address currency,
        uint256 pricePerSecond,
        uint256 available
    ) external {
        License registrar = new License(
            name,
            symbol,
            currency,
            pricePerSecond,
            available
        );
        uint256 contractCount = userLicenseCount[msg.sender]++;
        getLicense[msg.sender][contractCount] = address(registrar);
        licenses.push(address(registrar));
    }
}
