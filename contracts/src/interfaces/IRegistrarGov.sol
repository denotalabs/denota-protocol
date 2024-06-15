// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {INotaModule} from "./INotaModule.sol";

interface IRegistrarGov {

    event ModuleWhitelisted(address indexed user, INotaModule indexed module, bool isAccepted);

    event TokenWhitelisted(address caller, address indexed token, bool indexed isAccepted);
    
    function moduleWhitelisted(INotaModule module) external view returns (bool);

    function tokenWhitelisted(address token) external view returns (bool);
}