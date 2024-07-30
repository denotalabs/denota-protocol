// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;
import {IHooks} from "./IHooks.sol";

interface IRegistrarGov {

    event ContractURIUpdated();
    event ProtocolFeeSet(uint256 newFee);
    event ProtocolRevenueCollected(address indexed token, uint256 amount, address indexed to);
    event HookRevenueCollected(address indexed hook, address indexed token, uint256 amount, address indexed to, uint256 fee);
    
    function setContractURI(string calldata uri) external;

    function setProtocolFee(uint256 newFee) external;

    function hookWithdraw(address token, uint256 amount, address payoutAccount) external;

    function protocolWithdraw(address token, uint256 amount, address to) external;


    function contractURI() external view returns (string memory);

    function protocolFee() external returns(uint256);

    function hookRevenue(IHooks hook, address currency) external view returns(uint256);

    function hookTotalRevenue(IHooks hook, address currency) external view returns(uint256);

    function protocolRevenue(address currency) external view returns(uint256);

    function protocolTotalRevenue(address currency) external view returns(uint256);
}