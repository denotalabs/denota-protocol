// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface INotaFees {
    event FeeSet(address module, uint24 fees);
    function setFees(uint24 fees) external;
    function moduleWithdraw(address token, uint256 amount, address to) external;
}