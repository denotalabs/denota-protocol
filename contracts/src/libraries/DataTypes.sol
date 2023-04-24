// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC20/IERC20.sol";

// Might be able to just incorporate this into the CheqRegistrar
library DataTypes {
    struct Cheq {
        uint256 escrowed;
        uint256 createdAt; // Set by caller and immutable
        address currency; // Set by caller and immutable
        address module;
        // bool isFungible; // IDEA: Allow escrowing a single NFT
        // bool nftEscrowed;
    }

    struct WTFCFees {
        uint256 writeBPS;
        uint256 transferBPS;
        uint256 fundBPS;
        uint256 cashBPS;
    }
}
