// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {OperatorFeeModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import "openzeppelin/utils/Strings.sol";

/**
 * @notice A simple payment module that includes an IPFS hash for memos (included in the URI)
 * Ownership grants the right to receive direct payment
 * Can be used to track: Promise of payment, Request for payment, Payment, or a Past payment (Payment & Invoice)
 * Essentially what Bulla and Request currently support
 */
contract DirectPay is OperatorFeeModuleBase {
    struct Payment {
        address creditor;
        address debtor;
        uint256 amount; // Face value of the payment
        bool wasPaid; // TODO is this needed if using instant pay?
        string imageURI;
        string memoHash; // assumes ipfs://HASH
    }
    mapping(uint256 => Payment) public payInfo;

    event PaymentCreated(
        uint256 notaId,
        string memoHash,
        uint256 amount,
        uint256 timestamp,
        address referer,
        address creditor,
        address debtor,
        uint256 dueDate
    );
    error EscrowUnsupported();
    error AmountZero();
    error InvoiceWithPay();
    error InsufficientPayment();
    error AddressZero();
    error Disallowed();
    error OnlyOwner();
    error OnlyOwnerOrApproved();

    constructor(
        address registrar,
        DataTypes.WTFCFees memory _fees,
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
    ) public override onlyRegistrar returns (uint256) {
        (
            address toNotify,
            uint256 amount, // Face value (for invoices)
            // uint256 timestamp,
            uint256 dueDate,
            address dappOperator,
            string memory imageURI,
            string memory memoHash
        ) = abi.decode(
                initData,
                (address, uint256, uint256, address, string, string)
            );
        if (escrowed != 0) revert EscrowUnsupported();
        if (amount == 0) revert AmountZero(); // Removing this would allow user to send memos

        if (caller == owner) // Invoice
        {
            if (instant != 0) revert InvoiceWithPay();
            payInfo[notaId].creditor = caller;
            payInfo[notaId].debtor = toNotify;
            payInfo[notaId].amount = amount;
        } else if (owner == toNotify) // Payment
        {
            if (owner == address(0)) revert AddressZero();
            payInfo[notaId].creditor = toNotify;
            payInfo[notaId].debtor = caller;
            payInfo[notaId].amount = instant;
            payInfo[notaId].wasPaid = true;
        } else {
            revert Disallowed();
        }
        // payInfo[notaId].timestamp = timestamp;
        payInfo[notaId].memoHash = memoHash;
        payInfo[notaId].imageURI = imageURI;

        _logPaymentCreated(notaId, dappOperator, dueDate);

        return _takeReturnFee(currency, instant, dappOperator, 0);
    }

    function _logPaymentCreated(
        uint256 notaId,
        address referer,
        uint256 dueDate
    ) private {
        emit PaymentCreated(
            notaId,
            payInfo[notaId].memoHash,
            payInfo[notaId].amount,
            block.timestamp,
            referer,
            payInfo[notaId].creditor,
            payInfo[notaId].debtor,
            dueDate
        );
    }

    function processTransfer(
        address caller,
        address approved,
        address owner,
        address /*from*/,
        address /*to*/,
        uint256 /*notaId*/,
        DataTypes.Nota calldata nota,
        bytes memory data
    ) public override onlyRegistrar returns (uint256) {
        if (caller != owner && caller != approved) revert OnlyOwnerOrApproved();
        return
            _takeReturnFee(nota.currency, nota.escrowed, abi.decode(data, (address)), 1);
    }

    function processFund(
        address /*caller*/,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata initData
    ) public override onlyRegistrar returns (uint256) {
        if (owner == address(0)) revert AddressZero();
        if (amount != 0) revert EscrowUnsupported();
        if (instant != payInfo[notaId].amount) revert InsufficientPayment();
        if (payInfo[notaId].wasPaid) revert Disallowed();
        // require(caller == payInfo[notaId].debtor, "Only debtor"); // Should anyone be allowed to pay?
        payInfo[notaId].wasPaid = true;
        return
            _takeReturnFee(
                nota.currency,
                amount + instant,
                abi.decode(initData, (address)),
                2
            );
    }

    function processCash(
        address /*caller*/,
        address /*owner*/,
        address /*to*/,
        uint256 /*amount*/,
        uint256 /*notaId*/,
        DataTypes.Nota calldata /*nota*/,
        bytes calldata /*initData*/
    ) public view override onlyRegistrar returns (uint256) {
        revert Disallowed();
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*notaId*/,
        DataTypes.Nota calldata /*nota*/,
        bytes memory /*initData*/
    ) public view override onlyRegistrar {
        if (caller != owner) revert OnlyOwner();
        // require(wasPaid[notaId], "Module: Must be cashed first");
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payInfo[tokenId];

        string memory attributes = string(
            abi.encodePacked(
                ',{"trait_type":"Creditor","value":"',
                Strings.toHexString(uint256(uint160(payment.creditor))),
                '"},{"trait_type":"Debtor","value":"',
                Strings.toHexString(uint256(uint160(payment.debtor))),
                '"},{"trait_type":"Amount","value":"',
                Strings.toHexString(payment.amount),
                '"},{"trait_type":"Was Paid","value":"',
                payment.wasPaid  ? 'true' : 'false',
                '"}'
            )
        );

        return (attributes,
            string(
                abi.encodePacked(
                    ',"external_url":"',
                    abi.encodePacked(_URI, payInfo[tokenId].memoHash),
                    '","image":"',
                    payInfo[tokenId].imageURI, '"'
                )
        ));
    }
}
