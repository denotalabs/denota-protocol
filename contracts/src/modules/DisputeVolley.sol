// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";

/// @notice disputation mechanism is a settlement time w/ an extension if disputed. This can be counter disputed until one party gives up
abstract contract DisputeVolley is ModuleBase {

}
