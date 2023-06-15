// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity ^0.8.16;
// import "openzeppelin/token/ERC20/IERC20.sol";
// import {ICheqModule} from "../interfaces/ICheqModule.sol";

// interface ICheqRegistrar {
//     function write(
//         uint256 escrowed,
//         uint256 instant,
//         address owner,
//         bytes calldata moduleWriteData
//     ) external payable returns (uint256);

//     function transferFrom(address from, address to, uint256 tokenId) external;

//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId,
//         bytes memory moduleTransferData
//     ) external;

//     function fund(
//         uint256 tokenId,
//         uint256 amount,
//         uint256 instant,
//         bytes calldata fundData
//     ) external payable;

//     function cash(
//         uint256 tokenId,
//         uint256 amount,
//         address to,
//         bytes calldata cashData
//     ) external payable;

//     // function burn(uint256 tokenId) external;

//     function cheqEscrowed(uint256 cheqId) external view returns (uint256);
// }
