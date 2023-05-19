// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import {Base64Encoding} from "./Base64Encoding.sol";

/// What info do they want?
contract PayoutRegistrar is ERC721, Base64Encoding {
    struct Nota {
        uint256 createdAt;
        string docHash;
        string imageURI;
    }

    address public issuer;
    string public baseURI;
    mapping(uint256 => Nota) public notaInfo;
    uint256 private _totalSupply;
    error NotMinted();

    modifier isMinted(uint256 cheqId) {
        if (cheqId >= _totalSupply) revert NotMinted();
        _;
    }

    constructor(string memory _baseURI) ERC721("denota", "NOTA") {
        issuer = msg.sender;
        baseURI = _baseURI;
    }

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        address owner,
        string calldata metadata,
        string calldata imageURI
    ) public payable returns (uint256) {
        require(msg.sender == issuer, "");
        _mint(owner, _totalSupply);
        notaInfo[_totalSupply] = Nota(block.timestamp, metadata, imageURI);
        unchecked {
            return _totalSupply++;
        }
    }

    function tokenURI(
        uint256 notaId
    ) public view override isMinted(notaId) returns (string memory) {
        Nota memory nota = notaInfo[notaId];
        return
            _buildMetadata(itoa(nota.createdAt), nota.docHash, nota.imageURI);
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/
    function _buildMetadata(
        string memory createdAt,
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
                                '},{"trait_type":"Issuer","value":"',
                                issuer,
                                '"}]',
                                '",{"image_data":',
                                baseURI,
                                imageURI,
                                '},{"external_url":',
                                baseURI,
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

contract PayoutFactory {
    mapping(address => address) public getPayout;
    address[] public payouts;

    constructor() {}

    function deploy(address currency) external {
        PayoutRegistrar registrar = new PayoutRegistrar(currency); // TODO check that this succeeds
        getPayout[msg.sender] = address(registrar);
        payouts.push(address(registrar));
    }
}
