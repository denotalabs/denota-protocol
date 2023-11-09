// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "../../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin/utils/Strings.sol";
import {Nota} from "../libraries/DataTypes.sol";

/**
{
    "name": STRING_NAME,
    "image": URL_STRING: ipfs, https (recommended 350 x 350px),
    "image_data": SVG_DATA (Only use this if you're not including the image parameter),
    "external_url": (to allow users to leave OpenSea and view the item on your site),
    "description": human readable description of the item (markdown supported),
    "attributes": [
     ],
    "background_color": must be a six-character hexadecimal without a pre-pended #
    "animation_url": A URL to a multi-media attachment for the item. The file extensions GLTF, GLB, WEBM, MP4, M4V, OGV, and OGG are supported, along with the audio-only extensions MP3, WAV, and OGA Animation_url also supports HTML pages, allowing you to build rich experiences and interactive NFTs using JavaScript canvas, WebGL, and more. Scripts and relative paths within the HTML page are now supported. However, access to browser extensions is not supported.
    "youtube_url": A URL to a YT video
}

Registrar has structure:

{
    attributes: [timecreated, currency, escrowed {INSERT_MODULE_ATTRIBUTES}],
    {INSERT_MODULE_KEYS}
}
 */

contract NotaEncoding {
    using Strings for address;  // TODO move into NotaEncoding
    using Base64 for bytes;
    /// https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
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

    function toJSON(
        Nota memory nota,
        string memory moduleAttributes,
        string memory moduleKeys
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    bytes(
                        abi.encodePacked(
                            '{"attributes":[{"trait_type":"Currency","value":"',
                            Strings.toHexString(uint256(uint160(nota.currency)), 20),
                            '"},{"trait_type":"Escrowed","display_type":"number","value":',
                            itoa(nota.escrowed),
                            '},{"trait_type":"CreatedAt","display_type":"number","value":',
                            itoa(nota.createdAt),
                            '},{"trait_type":"Module","value":"',
                            Strings.toHexString(uint256(uint160(nota.module)), 20),
                            '"}',
                            moduleAttributes,  // of form: ',{"trait_type":"<trait>","value":"<value>"}'
                            ']',
                            moduleKeys, // of form: ',{"<key>":"<value>"}
                            '}'
                        )
                    ).encode()
                )
            );
    }
}
