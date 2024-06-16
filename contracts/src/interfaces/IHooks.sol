// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IHooks {
    function processWrite(
        address caller,
        uint256 notaId,
        address currency,
        uint256 escrowed,
        address owner,
        uint256 instant,
        bytes calldata hookData
    ) external returns (uint256);

    function processTransfer(
        address caller,
        uint256 notaId,
        uint256 escrowed,
        address owner,
        // address approved, // TODO should this be passed to hook too?
        address from,  // TODO doesn't `from` always equal owner?
        address to,
        bytes calldata hookData
    ) external returns (uint256);

    function processFund(
        address caller,
        uint256 notaId,
        uint256 escrowed,
        address owner,
        uint256 amount,
        uint256 instant,
        bytes calldata hookData
    ) external returns (uint256);

    function processCash(
        address caller,
        uint256 notaId,
        uint256 escrowed,
        address owner,
        address to,
        uint256 amount,
        bytes calldata hookData
    ) external returns (uint256);

    function processApproval(
        address caller,
        uint256 notaId,
        uint256 escrowed,
        address owner,
        address to
    ) external;

    function processTokenURI(
        uint256 notaId
    ) external view returns (string memory, string memory);
}
