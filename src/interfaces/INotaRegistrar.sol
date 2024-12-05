// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "openzeppelin/token/ERC20/IERC20.sol";
import {IHooks} from "../interfaces/IHooks.sol";

/**
 * @notice NotaRegistrar handles: Escrowing funds & Managing notas
 * @title  The Nota Registrar
 * @notice The main contract where users can WTFCATBU notas
 * @author Alejandro Almaraz
 */
interface INotaRegistrar {
    /// @notice Structure representing a Nota
    /// @dev Contains details about the Nota including escrowed amount, currency, and hooks
    struct Nota {
        uint256 escrowed; // Slot1
        address currency; // Slot2
        /* 96 bits free */
        IHooks hooks; // Slot3
        /* 96 bits free */
    }

    /// @notice Emitted when a Nota is written
    /// @param writer The address of the writer
    /// @param notaId The ID of the Nota
    /// @param currency The currency address
    /// @param escrowed The amount escrowed
    /// @param hook The hook contract address
    /// @param instant The amount forwarded instantly to the owner
    /// @param hookFee The fee taken by the hook
    /// @param hookData Additional data for the hook
    event Written(
        address indexed writer,
        uint256 indexed notaId,
        address currency,
        uint256 escrowed,
        IHooks indexed hook,
        uint256 instant,
        uint256 hookFee,
        bytes hookData
    );

    /// @notice Emitted when a Nota is transferred
    /// @param transferer The address of the transferer
    /// @param notaId The ID of the Nota
    /// @param hookFee The fee taken by the hook
    /// @param hookData Additional data for the hook
    event Transferred(address indexed transferer, uint256 indexed notaId, uint256 hookFee, bytes hookData);

    /// @notice Emitted when a Nota is funded
    /// @param funder The address of the funder
    /// @param notaId The ID of the Nota
    /// @param amount The amount to escrow
    /// @param instant The amount forwarded instantly to the owner
    /// @param hookFee The fee taken by the hook
    /// @param hookData Additional data for the hook
    event Funded(
        address indexed funder, uint256 indexed notaId, uint256 amount, uint256 instant, uint256 hookFee, bytes hookData
    );

    /// @notice Emitted when a Nota is cashed
    /// @param casher The address of the casher
    /// @param notaId The ID of the Nota
    /// @param to The address to which the amount is sent
    /// @param amount The amount cashed
    /// @param hookFee The fee taken by the hook
    /// @param hookData Additional data for the hook
    event Cashed(
        address indexed casher,
        uint256 indexed notaId,
        address indexed to,
        uint256 amount,
        uint256 hookFee,
        bytes hookData
    );

    /// @notice Emitted when a Nota is approved
    /// @param approver The address of the approver
    /// @param notaId The ID of the Nota
    /// @param hookFee The fee taken by the hook
    event Approved(address indexed approver, uint256 indexed notaId, uint256 hookFee);

    /// @notice Emitted when a Nota is burned
    /// @param burner The address of the burner
    /// @param notaId The ID of the Nota
    event Burned(address indexed burner, uint256 indexed notaId);

    /// @notice Error indicating that the Nota does not exist
    error NonExistent();

    /**
    * @notice Mints a nota to the owner, escrows tokens and forwards the instant amount to the owner
    * @dev Requires `owner` != address(0) and whatever the hook enforces. Transfers the currency tokens from the caller with hook fees added on top
    * @param currency The address of the currency to be used
    * @param escrowed The amount of tokens to be escrowed
    * @param instant The amount of tokens to be forwarded instantly to the owner
    * @param owner The address of the owner receiving the nota
    * @param hook The hook to be called
    * @param hookData The data to be passed to the hook
    * @return The ID of the newly minted nota
    */
    function write(
        address currency,
        uint256 escrowed,
        uint256 instant,
        address owner,
        IHooks hook,
        bytes calldata hookData
    ) external payable returns (uint256);

    /**
    * @notice Transfers the ownership of a given nota from one address to another address
    * @dev Enforces the transfer requirements (isApprovedOrOwner) and whatever the hook enforces. Hook fees are removed from the nota and fails if insufficient
    * @param from The current owner of the nota
    * @param to The address to receive the ownership of the given nota
    * @param notaId The unique identifier of the nota to be transferred
    */
    function transferFrom(address from, address to, uint256 notaId) external;

    /**
    * @notice Transfers the ownership of a given nota from one address to another address
    * @dev Enforces the transfer requirements (isApprovedOrOwner) and whatever the hook enforces. Hook fees are removed from the nota and fails if insufficient
    * @param from The current owner of the nota
    * @param to The address to receive the ownership of the given nota
    * @param notaId The unique identifier of the nota to be transferred
    * @param hookData The data to be passed to the hook
    */
    function safeTransferFrom(address from, address to, uint256 notaId, bytes memory hookData) external;

    /**
    * @notice Adds to the escrowed amount of a nota
    * @dev Transfers the currency tokens from the caller with hook fees added on top. No requirements except what the hook enforces
    * @param notaId The ID of the nota to fund
    * @param amount The amount to add to the escrow
    * @param instant The instant time for the funding
    * @param hookData Additional data for the hook
    */
    function fund(uint256 notaId, uint256 amount, uint256 instant, bytes calldata hookData) external payable;

    /**
    * @notice Removes from the escrowed amount of a nota
    * @dev No requirements except what the hook enforces. Removes hook fees from the amount and fails if insufficient
    * @param notaId The ID of the nota to cash out
    * @param amount The amount to remove from the escrow
    * @param to The address to send the cashed amount to
    * @param hookData Additional data for the hook
    */
    function cash(uint256 notaId, uint256 amount, address to, bytes calldata hookData) external payable;

    /**
    * @notice Approves a nota for transfer
    * @dev Caller must be the owner or approved for the nota or an operator for the owner. Hook fees are removed from the nota and fails if insufficient
    * @param to The address to approve for the transfer
    * @param notaId The ID of the nota to approve
    */
    function approve(address to, uint256 notaId) external;

    /**
    * @notice Burns the Nota's ownership, deletes notaInfo, and moves remaining escrowed funds to the hook's revenue
    * @dev Caller must be the owner or approved the Nota or an operator for the owner. Remaining nota funds are credited to the hook's revenue
    * @param notaId The ID of the Nota to burn
    */
    function burn(uint256 notaId) external;

    /**
    * @notice Updates the state of a Nota within its hook
    * @dev No requirements except what the hook enforces
    * @param notaId The ID of the Nota to update
    * @param hookData Additional data for the hook
    */
    function update(uint256 notaId, bytes calldata hookData) external;

    /**
    * @notice Returns the information of a Nota
    * @dev Fails if the Nota does not exist
    * @param notaId The ID of the Nota to get information for
    * @return Nota The Nota struct
    */
    function notaInfo(uint256 notaId) external view returns (Nota memory);

    /// @notice Returns the currency address associated with a given nota
    /// @param notaId The ID of the nota
    /// @return The address of the currency
    function notaCurrency(uint256 notaId) external view returns (address);

    /// @notice Returns the amount of currency escrowed for a given nota
    /// @param notaId The ID of the nota
    /// @return The amount of currency escrowed
    function notaEscrowed(uint256 notaId) external view returns (uint256);

    /// @notice Returns the hook contract address associated with a given nota
    /// @param notaId The ID of the nota
    /// @return The hooks associated with the nota
    function notaHooks(uint256 notaId) external view returns (IHooks);

    /// @notice Returns the nota and fetches the nota's hook specific data
    /// @param notaId The ID of the nota
    /// @return A tuple containing the Nota struct and additional nota hook data in bytes
    function notaData(uint256 notaId) external view returns (Nota memory, bytes memory);

    /// @notice Returns the full nota state and fetches the nota's hook specific data
    /// @param notaId The ID of the nota
    /// @return A tuple containing the NotaState struct and additional nota hook data in bytes
    function notaStateData(uint256 notaId) external view returns (IHooks.NotaState memory, bytes memory);
}
