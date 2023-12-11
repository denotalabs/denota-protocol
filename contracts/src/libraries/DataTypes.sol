// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC20/IERC20.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";

struct Nota {
    uint256 escrowed; // Slot 1
    uint256 createdAt; // Slot 2
    address currency; // Slot3 (120)
    INotaModule module; // Slot3 (240)
    // 16 bits free
    // address owner; // Slot4 (120)
    // address approved; // Slot4 (240)
    // 16 bits free
}

struct WTFCFees {
    uint256 writeBPS;
    uint256 transferBPS;
    uint256 fundBPS;
    uint256 cashBPS;
}

