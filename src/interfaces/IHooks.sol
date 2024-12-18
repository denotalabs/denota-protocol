// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

/// @title IHooks - Interface for Nota hook functionality
/// @notice Defines the core hooks that can be implemented to customize Nota behavior
interface IHooks {

    /// @notice Struct representing the current state of a Nota
    /// @param id The Nota id
    /// @param currency The currency address of the Nota
    /// @param escrowed The amount of funds escrowed in the Nota
    /// @param owner The owner of the Nota
    /// @param approved The approved address of the Nota
    struct NotaState {
        uint256 id;
        address currency;
        uint256 escrowed;
        address owner;
        address approved;
    }

    /// @notice Called before writing a new Nota
    /// @param caller msg.sender initiating the write call
    /// @param nota Current state of the Nota
    /// @param instant Amount to release instantly to the nota owner
    /// @param hookData Additional data passed to the hook
    /// @return bytes4 Function selector to validate the call and uint256 to charge as fee
    function beforeWrite(address caller, NotaState calldata nota, uint256 instant, bytes calldata hookData)
        external
        returns (bytes4, uint256);

    /// @notice Called before transferring a Nota
    /// @param caller msg.sender initiating the transfer call
    /// @param nota Current state of the Nota
    /// @param to Address to transfer the Nota to
    /// @param hookData Additional data passed to the hook
    /// @return bytes4 Function selector to validate the call and uint256 to charge as fee
    function beforeTransfer(address caller, NotaState calldata nota, address to, bytes calldata hookData)
        external
        returns (bytes4, uint256);

    /// @notice Called before funding a Nota
    /// @param caller msg.sender initiating the fund call
    /// @param nota Current state of the Nota
    /// @param amount Amount to fund the Nota with
    /// @param instant Amount to release instantly to the nota owner
    /// @param hookData Additional data passed to the hook
    /// @return bytes4 Function selector to validate the call and uint256 to charge as fee
    function beforeFund(
        address caller,
        NotaState calldata nota,
        uint256 amount,
        uint256 instant,
        bytes calldata hookData
    ) external returns (bytes4, uint256);

    /// @notice Called before withdrawing from a Nota
    /// @param caller msg.sender initiating the cash call
    /// @param nota Current state of the Nota
    /// @param to Address to withdraw the funds to
    /// @param amount Amount to withdraw from the Nota
    /// @param hookData Additional data passed to the hook
    /// @return bytes4 Function selector to validate the call and uint256 to charge as fee
    function beforeCash(address caller, NotaState calldata nota, address to, uint256 amount, bytes calldata hookData)
        external
        returns (bytes4, uint256);

    /// @notice Called before approving a Nota
    /// @param caller msg.sender initiating the approve call
    /// @param nota Current state of the Nota
    /// @param to Address to approve the Nota for
    /// @return bytes4 Function selector to validate the call and uint256 to charge as fee
    function beforeApprove(address caller, NotaState calldata nota, address to) external returns (bytes4, uint256);

    /// @notice Called before burning a Nota
    /// @param caller msg.sender initiating the burn call
    /// @param nota Current state of the Nota
    /// @param hookData Additional data passed to the hook
    /// @return bytes4 Function selector to validate the call
    function beforeBurn(address caller, NotaState calldata nota, bytes calldata hookData) external returns (bytes4);

    /// @notice Called before updating a Nota
    /// @param caller msg.sender initiating the update call
    /// @param nota Current state of the Nota
    /// @param hookData Additional data passed to the hook
    /// @return bytes4 Function selector to validate the call and uint256 to charge as fee
    function beforeUpdate(address caller, NotaState calldata nota, bytes calldata hookData) external returns (bytes4, uint256);

    /// @notice Called before querying the token URI
    /// @param caller msg.sender initiating the tokenURI call
    /// @param nota Current state of the Nota
    /// @return bytes4 Function selector to validate the call and tokenURI to return
    function beforeTokenURI(address caller, NotaState calldata nota)
        external
        view
        returns (bytes4, string memory, string memory);
    
    /// @notice used to get the hook's nota specific variables encoded as bytes
    /// @param notaId The Nota id to get the hook data for
    function notaBytes(uint256 notaId) external view returns (bytes memory);
}
