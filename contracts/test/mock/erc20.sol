// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "openzeppelin/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {

    constructor(uint256 _amount, string memory name, string memory symbol) ERC20(name, symbol){
        if (_amount>0) _mint(msg.sender, _amount);
    }
}

contract erc20 is ERC20 {

    constructor(uint256 _amount, string memory name, string memory symbol) ERC20(name, symbol){
        if (_amount>0) _mint(msg.sender, _amount);
    }
}
