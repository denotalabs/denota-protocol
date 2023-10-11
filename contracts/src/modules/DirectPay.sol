// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";

/**
 * @notice A simple payment module that includes an IPFS hash for memos (included in the URI)
 * Ownership grants the right to receive direct payment
 * Can be used to track: Promise of payment, Request for payment, Payment, or a Past payment (Payment & Invoice)
 * Essentially what Bulla and Request currently support
 */
contract DirectPay is ModuleBase {
    struct Payment {
        address creditor;
        address debtor;
        uint256 amount; // Face value of the payment
        // uint256 timestamp; // Record keeping timestamp BUG stack too deep in write, removed timestamp
        bool wasPaid; // TODO is this needed if using instant pay?
        string imageURI;
        string memoHash; // assumes ipfs://HASH
    }
    mapping(uint256 => Payment) public payInfo;

    event PaymentCreated(
        uint256 cheqId,
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
    ) ModuleBase(registrar, _fees) {
        _URI = __baseURI;
    }

    function processWrite(
        address caller,
        address owner,
        uint256 cheqId,
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
            payInfo[cheqId].creditor = caller;
            payInfo[cheqId].debtor = toNotify;
            payInfo[cheqId].amount = amount;
        } else if (owner == toNotify) // Payment
        {
            if (owner == address(0)) revert AddressZero();
            payInfo[cheqId].creditor = toNotify;
            payInfo[cheqId].debtor = caller;
            payInfo[cheqId].amount = instant;
            payInfo[cheqId].wasPaid = true;
        } else {
            revert Disallowed();
        }
        // payInfo[cheqId].timestamp = timestamp;
        payInfo[cheqId].memoHash = memoHash;
        payInfo[cheqId].imageURI = imageURI;

        _logPaymentCreated(cheqId, dappOperator, dueDate);

        return takeReturnFee(currency, instant, dappOperator, 0);
    }

    function _logPaymentCreated(
        uint256 cheqId,
        address referer,
        uint256 dueDate
    ) private {
        emit PaymentCreated(
            cheqId,
            payInfo[cheqId].memoHash,
            payInfo[cheqId].amount,
            block.timestamp,
            referer,
            payInfo[cheqId].creditor,
            payInfo[cheqId].debtor,
            dueDate
        );
    }

    function processTransfer(
        address caller,
        address approved,
        address owner,
        address /*from*/,
        address /*to*/,
        uint256 /*cheqId*/,
        address currency,
        uint256 escrowed,
        uint256 /*createdAt*/,
        bytes memory data
    ) public override onlyRegistrar returns (uint256) {
        if (caller != owner && caller != approved) revert OnlyOwnerOrApproved();
        return
            takeReturnFee(currency, escrowed, abi.decode(data, (address)), 1);
    }

    function processFund(
        address /*caller*/,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 cheqId,
        DataTypes.Nota calldata cheq,
        bytes calldata initData
    ) public override onlyRegistrar returns (uint256) {
        if (owner == address(0)) revert AddressZero();
        if (amount != 0) revert EscrowUnsupported();
        if (instant != payInfo[cheqId].amount) revert InsufficientPayment();
        if (payInfo[cheqId].wasPaid) revert Disallowed();
        // require(caller == payInfo[cheqId].debtor, "Only debtor"); // Should anyone be allowed to pay?
        payInfo[cheqId].wasPaid = true;
        return
            takeReturnFee(
                cheq.currency,
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
        uint256 /*cheqId*/,
        DataTypes.Nota calldata /*cheq*/,
        bytes calldata /*initData*/
    ) public view override onlyRegistrar returns (uint256) {
        revert Disallowed();
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*cheqId*/,
        DataTypes.Nota calldata /*cheq*/,
        bytes memory /*initData*/
    ) public view override onlyRegistrar {
        if (caller != owner) revert OnlyOwner();
        // require(wasPaid[cheqId], "Module: Must be cashed first");
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    ',"external_url":"',
                    abi.encodePacked(_URI, payInfo[tokenId].memoHash),
                    '","image":"',
                    payInfo[tokenId].imageURI
                )
            );
    }
}
