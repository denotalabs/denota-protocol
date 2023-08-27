// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {DataTypes} from "../libraries/DataTypes.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";

/**
 * @notice NotaRegistrar handles: Escrowing funds, and Storing nota data
 */
interface INotaRegistrar {
    function write(
        address currency,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address module,
        bytes calldata moduleWriteData
    ) external payable returns (uint256);

    // function safeWrite(
    //     address currency,
    //     uint256 escrowed,
    //     uint256 instant,
    //     address owner,
    //     address module,
    //     bytes calldata moduleWriteData
    // ) external payable returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory moduleTransferData
    ) external;

    function fund(
        uint256 notaId,
        uint256 amount,
        uint256 instant,
        bytes calldata fundData
    ) external payable;

    function cash(
        uint256 notaId,
        uint256 amount,
        address to,
        bytes calldata cashData
    ) external payable;

    function approve(address to, uint256 tokenId) external;

    // function burn(uint256 tokenId) external;

    // nota data
    function notaInfo(
        uint256 notaId
    ) external view returns (DataTypes.Nota memory);

    function notaCreatedAt(uint256 notaId) external view returns (uint256);
    
    function notaCurrency(uint256 notaId) external view returns (address);

    function notaEscrowed(uint256 notaId) external view returns (uint256);

    function notaModule(uint256 notaId) external view returns (address);

    function moduleWithdraw(address token,uint256 amount,address to) external;

    // function ownerOf(uint256 notaId) external view returns (address);

    // function totalSupply() public view returns (uint256);

    // function moduleWithdraw(
    //     address token,
    //     uint256 amount,
    //     address payoutAccount
    // ) external;
}