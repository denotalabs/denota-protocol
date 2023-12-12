// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC20/IERC20.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";

struct Nota {
    uint256 escrowed; // Slot 1
    address currency; // Slot2 (120)
    INotaModule module; // Slot2 (240)
    // 16 bits free
    // address owner; // Slot3 (120)
    // address approved; // Slot3 (240)
    // 16 bits free
}

struct WTFCFees {
    uint256 writeBPS;
    uint256 transferBPS;
    uint256 fundBPS;
    uint256 cashBPS;
}

