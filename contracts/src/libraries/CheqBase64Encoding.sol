// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

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
 */

contract CheqBase64Encoding {
    // string constant MODULE = '},{"trait_type": "Module","value":"';
    // string constant END = '"}]';
    // string constant TOKENDATA_CLOSE = '"}';

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

    function buildMetadata(
        string memory currency,
        string memory escrowed,
        // string memory createdAt,
        string memory module,
        string memory _tokenData
    ) internal pure returns (string memory) {
        // 76460 with storage constants, 74861 without
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"attributes":[{"trait_type":"Currency","value":"',
                                currency,
                                '"},{"trait_type":"Escrowed","display_type":"number","value":',
                                escrowed,
                                '},{"trait_type":"Module","value":"',
                                module,
                                '"}]',
                                _tokenData,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}
