// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {IHooks} from "./IHooks.sol";

interface IRegistrarGov {

    event ContractURIUpdated();
    event HookWhitelisted(address indexed user, IHooks indexed hook, bool isAccepted);
    event TokenWhitelisted(address caller, address indexed token, bool indexed isAccepted);
    event ProtocolFeeSet(uint256 newFee);
    event ProtocolRevenueCollected(address indexed token, uint256 amount, address indexed to);
    event HookRevenueCollected(address indexed hook, address indexed token, uint256 amount, address indexed to, uint256 fee);
    
    function contractURI() external view returns (string memory);

    function setContractURI(string calldata uri) external;
    
    function hookWhitelisted(IHooks hook) external view returns (bool);

    function tokenWhitelisted(address token) external view returns (bool);

    function whitelistHook(IHooks hook, bool isAccepted) external;

    function whitelistToken(address token, bool isAccepted) external;

    function hookWithdraw(address token, uint256 amount, address payoutAccount) external;

    function hookRevenue(IHooks hook, address currency) external view returns(uint256);

    function setProtocolFee(uint256 newFee) external;

    function protocolFee() external returns(uint256);

    function collectProtocolRevenue(address token, uint256 amount, address to) external;

    function hookTotalRevenue(IHooks hook, address currency) external view returns(uint256);

    function protocolRevenue(address currency) external view returns(uint256);

    function protocolTotalRevenue(address currency) external view returns(uint256);

    function validWrite(IHooks hook, address token) external view returns (bool);
}