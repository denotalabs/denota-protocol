// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC20/IERC20.sol";

library DataTypes {
    struct Nota {
        uint256 escrowed;
        uint256 createdAt; // Set by caller and immutable
        address currency; // Set by caller and immutable
        address module; // Set by caller and immutable
    }

    struct WTFCFees {
        uint256 writeBPS;
        uint256 transferBPS;
        uint256 fundBPS;
        uint256 cashBPS;
    }
}
