// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {ICheqModule} from "../interfaces/ICheqModule.sol";
import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

/**
 * Note: Only payments, allows sender to choose when to release and whether to reverse (assuming it's not released yet)
 */
contract ReversibleRelease is ModuleBase {
    struct Payment {
        address inspector;
        address creditor;
        address debtor;
        uint256 amount;
        string memoHash;
        string imageURI;
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
        address inspector
    );

    error OnlyOwner();
    error AmountZero();
    error Disallowed();
    error AddressZero();
    error OnlyInspector();
    error InvoiceWithPay();
    error InsufficientPayment();
    error OnlyToDebtorOrOwner();
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
    ) external override onlyRegistrar returns (uint256) {
        (
            address toNotify,
            address inspector,
            address dappOperator,
            uint256 amount, // Face value (for invoices)
            string memory memoHash,
            string memory imageURI
        ) = abi.decode(
                initData,
                (address, address, address, uint256, string, string)
            );
        if (caller == owner) // Invoice
        {
            if (instant != 0) revert InvoiceWithPay();
            if (amount == 0) revert AmountZero();
            payInfo[cheqId].creditor = caller;
            payInfo[cheqId].debtor = toNotify;
            payInfo[cheqId].amount = amount;
        } else if (owner == toNotify) // Payment
        {
            if (owner == address(0)) revert AddressZero();
            payInfo[cheqId].creditor = toNotify;
            payInfo[cheqId].debtor = caller;
            payInfo[cheqId].amount = escrowed;
        } else {
            revert Disallowed();
        }

        payInfo[cheqId].inspector = inspector;
        payInfo[cheqId].memoHash = memoHash;
        payInfo[cheqId].imageURI = imageURI;

        _logPaymentCreated(cheqId, dappOperator);

        return takeReturnFee(currency, escrowed + instant, dappOperator, 0);
    }

    function _logPaymentCreated(uint256 cheqId, address referer) private {
        emit PaymentCreated(
            cheqId,
            payInfo[cheqId].memoHash,
            payInfo[cheqId].amount,
            block.timestamp,
            referer,
            payInfo[cheqId].creditor,
            payInfo[cheqId].debtor,
            payInfo[cheqId].inspector
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
    ) external override onlyRegistrar returns (uint256) {
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
        DataTypes.Cheq calldata cheq,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        if (owner == address(0)) revert AddressZero();
        if (amount != payInfo[cheqId].amount) revert InsufficientPayment();
        // if (caller != payInfo[cheqId].debtor) revert OnlyDebtor(); // Should anyone be allowed to pay?
        // if (payInfo[cheqId].wasPaid) revert Disallowed();
        // payInfo[cheqId].wasPaid = true;
        return
            takeReturnFee(
                cheq.currency,
                amount + instant,
                abi.decode(initData, (address)),
                2
            );
    }

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 amount,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        if (caller != payInfo[cheqId].inspector) revert OnlyInspector();
        if (to != payInfo[cheqId].debtor && to != owner)
            revert OnlyToDebtorOrOwner();
        return
            takeReturnFee(
                cheq.currency,
                amount,
                abi.decode(initData, (address)),
                3
            );
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*cheqId*/,
        DataTypes.Cheq calldata /*cheq*/,
        bytes memory /*initData*/
    ) external view override onlyRegistrar {
        if (caller != owner) revert OnlyOwner();
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
