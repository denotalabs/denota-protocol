// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IHooks {
    struct NotaState {
        uint256 notaId;
        address currency;
        uint256 escrowed;
        address owner;
        address approved;
    }

    function beforeWrite(
        address caller,
        NotaState calldata nota,
        uint256 instant,
        bytes calldata hookData
    ) external returns (uint256);

    function beforeTransfer(
        address caller,
        NotaState calldata nota,
        address to,
        bytes calldata hookData
    ) external returns (uint256);

    function beforeFund(
        address caller,
        NotaState calldata nota,
        uint256 amount,
        uint256 instant,
        bytes calldata hookData
    ) external returns (uint256);

    function beforeCash(
        address caller,
        NotaState calldata nota,
        address to,
        uint256 amount,
        bytes calldata hookData
    ) external returns (uint256);

    function beforeApprove(
        address caller,
        NotaState calldata nota,
        address to
    ) external returns (uint256);

    function beforeBurn(
        address caller,
        NotaState calldata nota
    ) external;

    function beforeTokenURI(
        uint256 notaId
    ) external view returns (string memory, string memory);
}