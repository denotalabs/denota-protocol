// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC20/IERC20.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";

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
        INotaModule module; // Slot3 /// Hook packing: mapping(INotaModule module => uint96 index) and store uint96 here
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
        INotaModule indexed module,
        uint256 instant,
        uint256 moduleFee,
        bytes hookData
    );
    event Transferred(
        address indexed transferer,
        uint256 indexed notaId,
        uint256 moduleFee,
        bytes hookData
    );
    event Funded(
        address indexed funder,
        uint256 indexed notaId,
        uint256 amount,
        uint256 instant,
        uint256 moduleFee,
        bytes hookData
    );
    event Cashed(
        address indexed casher,
        uint256 indexed notaId,
        address indexed to,
        uint256 amount,
        uint256 moduleFee,
        bytes hookData
    );

    error NonExistent();
    error InvalidWrite(INotaModule, address);

    function write(
        address currency,
        uint256 escrowed,
        uint256 instant,
        address owner,
        INotaModule module,
        bytes calldata moduleWriteData
    ) external payable returns (uint256);

    // function safeWrite(
    //     address currency,
    //     uint256 escrowed,
    //     uint256 instant,
    //     address owner,
    //     address module,
    //     bytes calldata hookData
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

    function notaInfo(uint256 notaId) external view returns (Nota memory);
    
    function notaCurrency(uint256 notaId) external view returns (address);

    function notaEscrowed(uint256 notaId) external view returns (uint256);

    function notaModule(uint256 notaId) external view returns (INotaModule);

    function moduleWithdraw(address token, uint256 amount, address payoutAccount) external;

    function moduleRevenue(INotaModule module, address currency) external view returns(uint256);
}
