// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {Nota} from "../libraries/DataTypes.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";

/**
 * @notice NotaRegistrar handles: Escrowing funds, and Storing nota data
 */
 // NOTE: If Registrar fee storing, Uniswapv4 has this inherit a IFees interface here as well. 
 /**
 * @title  The Nota Payment Registrar
 * @notice The main contract where users can WTFCA notas
 * @author Alejandro Almaraz
 * @dev    Tracks ownership of notas' data + escrow, and collects revenue.
 */

interface INotaRegistrar {

    event Written(
        address indexed caller,
        uint256 notaId,
        address indexed owner, // Question is this needed considering ERC721 _mint() emits owner `from` address(0) `to` owner?
        uint256 instant,
        address indexed currency,
        uint256 escrowed,
        uint256 timestamp, // Question Do these events need timestamps?
        uint256 moduleFee,
        INotaModule module,
        bytes moduleData
    );
    event Transferred(  // TODO does this need `from` since ERC721 already has it?
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 moduleFee,
        bytes transferData,
        uint256 timestamp
    ); // TODO needs moduleBytes
    event Funded(
        address indexed funder,
        uint256 indexed notaId,
        uint256 amount,
        uint256 instant,
        bytes indexed fundData,
        uint256 moduleFee,
        uint256 timestamp
    );
    event Cashed(
        address indexed casher,
        uint256 indexed notaId,
        address to,
        uint256 amount,
        bytes indexed cashData,
        uint256 moduleFee,
        uint256 timestamp
    );

    error SendFailed();
    error SelfApproval();
    error NonExistent();
    error InvalidWrite(INotaModule, address);
    error InsufficientValue(uint256, uint256);
    error InsufficientEscrow(uint256, uint256);

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

    function notaInfo(
        uint256 notaId
    ) external view returns (Nota memory);
    
    function notaCurrency(uint256 notaId) external view returns (address);

    function notaEscrowed(uint256 notaId) external view returns (uint256);

    function notaModule(uint256 notaId) external view returns (INotaModule);

    function moduleWithdraw(
        address token,
        uint256 amount,
        address payoutAccount
    ) external;

    function moduleRevenue(INotaModule module, address currency) external view returns(uint256);
}
