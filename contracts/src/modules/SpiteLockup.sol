// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";

/// @notice Sender pays reciever and can spite where the sender gets back the money after X amount of time
abstract contract SpiteLockup is ModuleBase {

}
