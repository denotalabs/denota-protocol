// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

interface IHooks {
    struct NotaState {
        uint256 id;
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
    ) external returns (bytes4, uint256);

    function beforeTransfer(
        address caller,
        NotaState calldata nota,
        address to,
        bytes calldata hookData
    ) external returns (bytes4, uint256);

    function beforeFund(
        address caller,
        NotaState calldata nota,
        uint256 amount,
        uint256 instant,
        bytes calldata hookData
    ) external returns (bytes4, uint256);

    function beforeCash(
        address caller,
        NotaState calldata nota,
        address to,
        uint256 amount,
        bytes calldata hookData
    ) external returns (bytes4, uint256);

    function beforeApprove(
        address caller,
        NotaState calldata nota,
        address to
    ) external returns (bytes4, uint256);

    function beforeBurn(
        address caller,
        NotaState calldata nota
    ) external returns (bytes4);

    function beforeTokenURI(
        address caller,
        NotaState calldata nota
    ) external view returns (bytes4, string memory, string memory);
}