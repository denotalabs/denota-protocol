// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC20/IERC20.sol";
import {IHooks} from "../interfaces/IHooks.sol";

/**
 * @notice NotaRegistrar handles: Escrowing funds, and Storing nota data
 * @title  The Nota Registrar
 * @notice The main contract where users can WTFCA notas
 * @author Alejandro Almaraz
 * @dev    Tracks ownership of notas' data + escrow, and collects revenue.
 */
interface INotaRegistrar {
    struct Nota {
        uint256 escrowed; // Slot 1
        address currency; // Slot2
        /* 96 bits free */
        IHooks hook; // Slot3 /// Hook packing: mapping(IHooks hook => uint96 index) and store uint96 here
        /* 96 bits free */

        // address owner; // Slot4 (160)
        /* 96 bits free */
        // address approved; // Slot5 (160)
        /* 96 bits free */
        // AssetType assetType; (8 bits)
    }

    event Written (
        address indexed writer,
        uint256 indexed notaId,
        address currency,
        uint256 escrowed,
        IHooks indexed hook,
        uint256 instant,
        uint256 hookFee,
        bytes hookData
    );
    event Transferred(
        address indexed transferer,
        uint256 indexed notaId,
        uint256 hookFee,
        bytes hookData
    );
    event Funded(
        address indexed funder,
        uint256 indexed notaId,
        uint256 amount,
        uint256 instant,
        uint256 hookFee,
        bytes hookData
    );
    event Cashed(
        address indexed casher,
        uint256 indexed notaId,
        address indexed to,
        uint256 amount,
        uint256 hookFee,
        bytes hookData
    );
    event Approved(
        address indexed approver,
        uint256 indexed notaId,
        uint256 hookFee
    );

    error NonExistent();
    error InvalidWrite(IHooks, address);

    function write(
        address currency,
        uint256 escrowed,
        uint256 instant,
        address owner,
        IHooks hook,
        bytes calldata hookData
    ) external payable returns (uint256);

    // function safeWrite(
    //     address currency,
    //     uint256 escrowed,
    //     uint256 instant,
    //     address owner,
    //     address hook,
    //     bytes calldata hookData
    // ) external payable returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory hookData
    ) external;

    function fund(
        uint256 notaId,
        uint256 amount,
        uint256 instant,
        bytes calldata hookData
    ) external payable;

    function cash(
        uint256 notaId,
        uint256 amount,
        address to,
        bytes calldata hookData
    ) external payable;

    function approve(address to, uint256 tokenId) external;

    function notaInfo(uint256 notaId) external view returns (Nota memory);
    
    function notaCurrency(uint256 notaId) external view returns (address);

    function notaEscrowed(uint256 notaId) external view returns (uint256);

    function notaHook(uint256 notaId) external view returns (IHooks);

    function hookWithdraw(address token, uint256 amount, address payoutAccount) external;

    function hookRevenue(IHooks hook, address currency) external view returns(uint256);
}
