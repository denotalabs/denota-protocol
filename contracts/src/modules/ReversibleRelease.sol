// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {OperatorFeeModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import {NotaEncoding} from "../libraries/Base64Encoding.sol";
import "openzeppelin/utils/Strings.sol";

/**
 * Note: Only payments, allows sender to choose when to release and whether to reverse (assuming it's not released yet)
 */
contract ReversibleRelease is OperatorFeeModuleBase {
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
        uint256 notaId,
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
            payInfo[notaId].creditor = caller;
            payInfo[notaId].debtor = toNotify;
            payInfo[notaId].amount = amount;
        } else if (owner == toNotify) // Payment
        {
            if (owner == address(0)) revert AddressZero();
            payInfo[notaId].creditor = toNotify;
            payInfo[notaId].debtor = caller;
            payInfo[notaId].amount = escrowed;
        } else {
            revert Disallowed();
        }

        payInfo[notaId].inspector = inspector;
        payInfo[notaId].memoHash = memoHash;
        payInfo[notaId].imageURI = imageURI;

        _logPaymentCreated(notaId, dappOperator);

        return takeReturnFee(currency, escrowed + instant, dappOperator, 0);
    }

    function _logPaymentCreated(uint256 notaId, address referer) private {
        emit PaymentCreated(
            notaId,
            payInfo[notaId].memoHash,
            payInfo[notaId].amount,
            block.timestamp,
            referer,
            payInfo[notaId].creditor,
            payInfo[notaId].debtor,
            payInfo[notaId].inspector
        );
    }

    function processTransfer(
        address caller,
        address approved,
        address owner,
        address /*from*/,
        address /*to*/,
        uint256 /*notaId*/,
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
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        if (owner == address(0)) revert AddressZero();
        if (amount != payInfo[notaId].amount) revert InsufficientPayment();
        // if (caller != payInfo[notaId].debtor) revert OnlyDebtor(); // Should anyone be allowed to pay?
        // if (payInfo[notaId].wasPaid) revert Disallowed();
        // payInfo[notaId].wasPaid = true;
        return
            takeReturnFee(
                nota.currency,
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
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        if (caller != payInfo[notaId].inspector) revert OnlyInspector();
        if (to != payInfo[notaId].debtor && to != owner)
            revert OnlyToDebtorOrOwner();
        return
            takeReturnFee(
                nota.currency,
                amount,
                abi.decode(initData, (address)),
                3
            );
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*notaId*/,
        DataTypes.Nota calldata /*nota*/,
        bytes memory /*initData*/
    ) external view override onlyRegistrar {
        if (caller != owner) revert OnlyOwner();
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payInfo[tokenId];

         string memory attributes = string(abi.encodePacked(
            ',{"trait_type":"Inspector","value":"',
            Strings.toHexString(uint256(uint160(payment.inspector))),
            '"},{"trait_type":"Creditor","value":"',
            Strings.toHexString(uint256(uint160(payment.creditor))),
            '"},{"trait_type":"Debtor","value":"',
            Strings.toHexString(uint256(uint160(payment.debtor))),
            '"},{"trait_type":"Amount","display_type":"number","value":',
            itoa(payment.amount),
            '}'));
        
        if (bytes(_URI).length == 0) {
            return (attributes, "");
        } else {
            return (attributes,  string(abi.encodePacked(',"image":"', _URI, payment.imageURI, '"',
                ',"external_url":"', _URI, payment.memoHash, '"')));
        }
    }
}
