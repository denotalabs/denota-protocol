// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {IHooks} from "./IHooks.sol";

interface IRegistrarGov {

    event HookWhitelisted(address indexed user, IHooks indexed hook, bool isAccepted);

    event TokenWhitelisted(address caller, address indexed token, bool indexed isAccepted);

    function setContractURI(string calldata uri) external;
    
    function hookWhitelisted(IHooks hook) external view returns (bool);

    function tokenWhitelisted(address token) external view returns (bool);

    function whitelistHook(IHooks hook, bool isAccepted) external;

    function whitelistToken(address token, bool isAccepted) external;

    function hookWithdraw(address token, uint256 amount, address payoutAccount) external;

    function hookRevenue(IHooks hook, address currency) external view returns(uint256);
}