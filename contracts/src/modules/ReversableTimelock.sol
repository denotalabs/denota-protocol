// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";

/**
 * Note: Only payments, allows sender to choose when to release and whether to reverse (assuming it's not released yet)
 */
contract ReversableTimelock is ModuleBase {
    struct Payment {
        address inspector;
        address payer;
        uint256 inspectionEnd;
        bytes32 memoHash;
    }
    mapping(uint256 => Payment) public payments;
    event PaymentCreated();

    error EscrowUnsupported();
    error AmountZero();
    error InvoiceWithPay();
    error InsufficientPayment();
    error AddressZero();
    error Disallowed();
    error OnlyOwner();

    constructor(
        address registrar,
        WTFCFees memory _fees,
        string memory __baseURI
    ) OperatorFeeModuleBase(registrar, _fees) {
        _URI = __baseURI;
    }

    function processWrite(
        address caller,
        address owner,
        uint256 notaId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        (
            address inspector,
            uint256 inspectionEnd,
            address dappOperator,
            bytes32 memoHash
        ) = abi.decode(initData, (address, uint256, address, bytes32));
        require((caller != owner) && (owner != address(0)), "Invalid Params");

        payments[notaId].inspector = inspector;
        payments[notaId].inspectionEnd = inspectionEnd;
        payments[notaId].payer = caller;
        payments[notaId].memoHash = memoHash;

        return _takeReturnFee(currency, escrowed + instant, dappOperator, 0);
    }

    function processTransfer(
        address /*caller*/,
        address /*approved*/,
        address /*owner*/,
        address /*from*/,
        address /*to*/,
        uint256 /*notaId*/,
        Nota calldata nota,
        bytes memory data
    ) external override onlyRegistrar returns (uint256) {
        return _takeReturnFee(nota.currency, 0, abi.decode(data, (address)), 1);
    }

    function processFund(
        address, // caller,
        address, // owner,
        uint256, // amount,
        uint256, // instant,
        uint256, // notaId,
        Nota calldata, // nota,
        bytes calldata // initData
    ) external view override onlyRegistrar returns (uint256) {
        require(false, "");
        return 0;
    }

    function processCash(
        address caller,
        address /*owner*/,
        address /*to*/,
        uint256 amount,
        uint256 notaId,
        Nota calldata nota,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        require(
            caller == payments[notaId].inspector,
            "Inspector cash for owner"
        );
        return
            _takeReturnFee(
                nota.currency,
                amount,
                abi.decode(initData, (address)),
                3
            );
    }

    function processApproval(
        address caller,
        address owner,
        address to,
        uint256 notaId,
        Nota calldata nota
    ) external override onlyRegistrar {}

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        return ("",
            bytes(_URI).length > 0
                ? string(abi.encodePacked(',"external_url":', _URI, tokenId))
                : "");

        // return string(abi.encode(_URI, payments[tokenId].memoHash));
    }
}
