// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/utils/Base64.sol";

// Issue Nota with VC with currency
// Issuer has their own contract with mint privilege
contract PayoutRegistrar is ERC721, Base64 {
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
        require(msg.sender == issuer, "NOT_ISSUER");
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

    function itoa32(uint x) private pure returns (uint y) {
        unchecked {
            require(x < 1e32);
            y = 0x3030303030303030303030303030303030303030303030303030303030303030;
            y += x % 10;
            x /= 10;
            y += x % 10 << 8;
            x /= 10;
            y += x % 10 << 16;
            x /= 10;
            y += x % 10 << 24;
            x /= 10;
            y += x % 10 << 32;
            x /= 10;
            y += x % 10 << 40;
            x /= 10;
            y += x % 10 << 48;
            x /= 10;
            y += x % 10 << 56;
            x /= 10;
            y += x % 10 << 64;
            x /= 10;
            y += x % 10 << 72;
            x /= 10;
            y += x % 10 << 80;
            x /= 10;
            y += x % 10 << 88;
            x /= 10;
            y += x % 10 << 96;
            x /= 10;
            y += x % 10 << 104;
            x /= 10;
            y += x % 10 << 112;
            x /= 10;
            y += x % 10 << 120;
            x /= 10;
            y += x % 10 << 128;
            x /= 10;
            y += x % 10 << 136;
            x /= 10;
            y += x % 10 << 144;
            x /= 10;
            y += x % 10 << 152;
            x /= 10;
            y += x % 10 << 160;
            x /= 10;
            y += x % 10 << 168;
            x /= 10;
            y += x % 10 << 176;
            x /= 10;
            y += x % 10 << 184;
            x /= 10;
            y += x % 10 << 192;
            x /= 10;
            y += x % 10 << 200;
            x /= 10;
            y += x % 10 << 208;
            x /= 10;
            y += x % 10 << 216;
            x /= 10;
            y += x % 10 << 224;
            x /= 10;
            y += x % 10 << 232;
            x /= 10;
            y += x % 10 << 240;
            x /= 10;
            y += x % 10 << 248;
        }
    }

    function itoa(uint x) internal pure returns (string memory s) {
        unchecked {
            if (x == 0) return "0";
            else {
                uint c1 = itoa32(x % 1e32);
                x /= 1e32;
                if (x == 0) s = string(abi.encode(c1));
                else {
                    uint c2 = itoa32(x % 1e32);
                    x /= 1e32;
                    if (x == 0) {
                        s = string(abi.encode(c2, c1));
                        c1 = c2;
                    } else {
                        uint c3 = itoa32(x);
                        s = string(abi.encode(c3, c2, c1));
                        c1 = c3;
                    }
                }
                uint z = 0;
                if (c1 >> 128 == 0x30303030303030303030303030303030) {
                    c1 <<= 128;
                    z += 16;
                }
                if (c1 >> 192 == 0x3030303030303030) {
                    c1 <<= 64;
                    z += 8;
                }
                if (c1 >> 224 == 0x30303030) {
                    c1 <<= 32;
                    z += 4;
                }
                if (c1 >> 240 == 0x3030) {
                    c1 <<= 16;
                    z += 2;
                }
                if (c1 >> 248 == 0x30) {
                    z += 1;
                }
                assembly {
                    let l := mload(s)
                    s := add(s, z)
                    mstore(s, sub(l, z))
                }
            }
        }
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
