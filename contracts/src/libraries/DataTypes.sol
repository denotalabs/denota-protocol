// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC20/IERC20.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";

// enum AssetType {ERC20, ERC721, ERC1155}

struct Nota {
    uint256 escrowed; // Slot 1 (256)
    address currency; // Slot2 (160)
    // 96 bits free
    INotaModule module; // Slot3 (160) // mapping(INotaModule module => uint96 index) and store uint96 here
    // 96 bits free

    // address owner; // Slot4 (160)
    // 96 bits free

    // address approved; // Slot5 (160)
    // 96 bits free

    // AssetType assetType; (8 bits)
}
