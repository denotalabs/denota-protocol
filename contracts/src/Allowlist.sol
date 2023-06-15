// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Base64.sol";
import "openzeppelin/utils/Strings.sol";

/// TODO use one with a merkle list
/// TODO make one with a ZK proof (client can create a proof that they are on the list, submit with tx)
// https://www.freecodecamp.org/news/how-to-implement-whitelist-in-smartcontracts-erc-721-nft-erc-1155-and-others/
contract Allowlist is ERC721, Ownable {
    using SafeERC20 for IERC20;
    using Strings for address;
    using Strings for uint256;

    struct Nota {
        uint256 escrowed;
        address asset;
    }

    mapping(uint256 => Nota) public notaInfo;
    mapping(address => bool) public allowList;
    mapping(address => bool) public assetList;
    uint256 private _totalSupply;

    error InsufficientValue(uint256, uint256);
    error SendFailed();

    constructor() ERC721("allow", "ALLOW") {}

    /*/////////////////////// WTFCAT ////////////////////////////*/
    function write(
        address asset,
        uint256 escrowed,
        address owner
    ) public payable returns (uint256) {
        require(allowList[msg.sender] && assetList[asset], "NOT_ALLOWED");

        if (asset == address(0)) {
            if (msg.value < escrowed) {
                // TODO: just let the call fail instead?
                revert InsufficientValue(escrowed, msg.value);
            } else {
                (bool sent, ) = address(this).call{value: escrowed}("");
                if (!sent) revert SendFailed();
            }
        } else {
            IERC20(asset).transferFrom(_msgSender(), address(this), escrowed);
        }

        _mint(owner, _totalSupply);
        notaInfo[_totalSupply] = Nota(escrowed, asset);

        unchecked {
            return _totalSupply++;
        }
    }

    function transferFrom(address from, address to, uint256 notaId) public {
        require(allowList[to], "NOT_ALLOWED");
        _transfer(from, to, notaId);
    }

    function cash(uint256 notaId) public {
        require(msg.sender == ownerOf(notId), "ONLY_OWNER");
        Nota memory nota = notaInfo[notaId];

        if (nota.asset == address(0)) {
            address payable owner = payable(ownerOf(notaId));
            (bool sent, ) = owner.call{value: nota.escrowed}("");
            if (!sent) revert SendFailed();
        } else {
            address owner = ownerOf(notaId);
            IERC20(nota.asset).transfer(owner, nota.escrowed);
        }
    }

    function tokenURI(
        uint256 notaId
    ) public view override returns (string memory) {
        _requireMinted(notaId);
        Nota memory nota = notaInfo[notaId];
        return
            _buildMetadata(
                nota.asset.toHexString(),
                nota.escrowed.toString(),
                nota.sender.toHexString(),
                nota.cashed
            );
    }

    /*///////////////////// URI FUNCTIONS ///////////////////////*/
    function _buildMetadata(
        string memory currency,
        string memory escrowed,
        string memory sender,
        bool cashed
    ) internal view returns (string memory) {
        string memory isCashed = cashed ? "True" : "False";
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"attributes":[{"trait_type":"Asset","value":"',
                                currency,
                                '"},{"trait_type":"Reverser","value":"',
                                reverser.toHexString(),
                                '},{"trait_type":"Escrowed","value":',
                                escrowed,
                                '},{"trait_type":"Sender","value":"',
                                sender,
                                '"},{"trait_type":"Cashed","value":"',
                                isCashed,
                                '"}]',
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /*///////////////////// BATCH FUNCTIONS ///////////////////////*/
    // function writeBatch(
    //     uint256[] calldata escrowedAmounts,
    //     address[] calldata owners,
    //     string[] calldata docHashes,
    //     string[] calldata imageURIs
    // ) public payable returns (uint256[] memory notaIds) {
    //     uint256 numWrites = escrowedAmounts.length;

    //     require(
    //         numWrites == escrowedAmounts.length &&
    //             numWrites == owners.length &&
    //             numWrites == docHashes.length &&
    //             numWrites == imageURIs.length,
    //         "Input arrays must have the same length"
    //     );
    //     for (uint256 i = 0; i < numWrites; i++) {
    //         notaIds[i] = write(
    //             escrowedAmounts[i],
    //             owners[i],
    //             docHashes[i],
    //             imageURIs[i]
    //         );
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
    function notaEscrowed(uint256 notaId) public view returns (uint256) {
        require(_exists(notaId));
        return notaInfo[notaId].escrowed;
    }

    function notaAsset(uint256 notaId) public view returns (address) {
        require(_exists(notaId));
        return notaInfo[notaId].asset;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function itoa32(uint x) public pure returns (uint y) {
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

    function itoa(uint x) public pure returns (string memory s) {
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
}
