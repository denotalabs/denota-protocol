// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";


contract Noop is ModuleBase {
    constructor(address registrar) ModuleBase(registrar) {
    }
}