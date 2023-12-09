// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IRegistrarGov {
    event ModuleWhitelisted(
        address indexed user,
        address indexed module,
        bool isAccepted,
        uint256 timestamp
    );

    event TokenWhitelisted(
        address caller,
        address indexed token,
        bool indexed accepted,
        uint256 timestamp
    );
    
    function moduleWhitelisted(
        address module
    ) external view returns (bool); // addressWhitelisted, bytecodeWhitelisted

    function tokenWhitelisted(address token) external view returns (bool);

    // function moduleWithdraw(
    //     address token,
    //     uint256 amount,
    //     address payoutAccount
    // ) external;
}