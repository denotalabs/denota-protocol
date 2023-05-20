// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/Base64.sol";
import {ModuleBase} from "./ModuleBase.sol";

/// Allows Kleros to rule on reversals (and how much)
contract KlerosEscrow is ERC721, Base64 {

}
