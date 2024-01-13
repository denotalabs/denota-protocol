// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import "openzeppelin/utils/Strings.sol";

/**
 * Note: Allows sender to choose when to release and whether to reverse (assuming it's not released yet)
 */
contract ReversibleReleaseInvoice is ModuleBase {
    struct Payment {
        address inspector;
        address creditor;
        address debtor;
        uint256 amount;
        string external_url;
        string imageURI;
    }
    mapping(uint256 => Payment) public payInfo;

    event PaymentCreated(
        uint256 notaId,
        string external_url,
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

    constructor(address registrar) ModuleBase(registrar) {
    }

    function processWrite(
        address caller,
        address owner,
        uint256 notaId,
        address /*currency*/,
        uint256 escrowed,
        uint256 instant,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        (
            address debtor,
            address inspector,
            uint256 amount,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                initData,
                (address, address, uint256, string, string)
            );

        if (caller != owner) revert();
        if (instant != 0) revert InvoiceWithPay();
        if (amount == 0) revert AmountZero();
        if (inspector == address(0)) revert AddressZero();
        
        payInfo[notaId] = Payment({
            inspector: inspector,
            creditor: caller,
            debtor: debtor,
            amount: amount,
            external_url: external_url,
            imageURI: imageURI
        });

        emit PaymentCreated(
            notaId,
            external_url,
            amount,
            block.timestamp,
            msg.sender,
            caller,
            debtor,
            inspector
        );

        return 0;
    }

    function processFund(
        address /*caller*/,
        address owner,
        uint256 amount,
        uint256 /*instant*/,
        uint256 notaId,
        Nota calldata /*nota*/,
        bytes calldata /*initData*/
    ) external override onlyRegistrar returns (uint256) {
        if (owner == address(0)) revert AddressZero();
        if (amount != payInfo[notaId].amount) revert InsufficientPayment();
        // if (caller != payInfo[notaId].debtor) revert OnlyDebtor(); // Should anyone be allowed to pay?
        // if (payInfo[notaId].wasPaid) revert Disallowed();
        // payInfo[notaId].wasPaid = true;
        return 0;
    }

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 amount,
        uint256 notaId,
        Nota calldata nota,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        if (caller != payInfo[notaId].inspector) revert OnlyInspector();
        if (to != payInfo[notaId].debtor && to != owner)
            revert OnlyToDebtorOrOwner();
        return 0;
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/
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
            '"},{"trait_type":"Amount","value":"',
            Strings.toHexString(payment.amount),
            '"}'));
        
        if (bytes(_URI).length == 0) {
            return (attributes, "");
        } else {
            return (attributes,  string(abi.encodePacked(',"image":"', _URI, payment.imageURI, '"',
                ',"external_url":"', _URI, payment.external_url, '"')));
        }
    }
}

contract ReversibleReleasePayment is ModuleBase {
    struct Payment {
        address payer;
        address inspector;
        string external_url;
        string imageURI;
    }
    mapping(uint256 notaId => Payment payment) public payments;

    event PaymentCreated(uint256 notaId, string external_url, address inspector);
    error OnlyOwner();
    error Disallowed();
    error AddressZero();
    error OnlyInspector();
    error OnlyOwnerOrApproved();

    constructor(address registrar) ModuleBase(registrar) {
    }

    function processWrite(
        address caller,
        address /*owner*/,
        uint256 notaId,
        address /*currency*/,
        uint256 /*escrowed*/,
        uint256 /*instant*/,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        (
            address inspector,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                initData,
                (address, string, string)
            );
        
        if (inspector == address(0)) revert AddressZero();

        payments[notaId] = Payment(caller, inspector, external_url, imageURI);

        emit PaymentCreated(notaId, external_url, inspector);
        return 0;
    }

    function processFund(
        address /*caller*/,
        address /*owner*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/,
        bytes calldata /*initData*/
    ) external override onlyRegistrar returns (uint256) {
        revert Disallowed();
    }

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 /*amount*/,
        uint256 notaId,
        Nota calldata /*nota*/,
        bytes calldata /*initData*/
    ) external override onlyRegistrar returns (uint256) {
        require(caller == payments[notaId].inspector, "ONLY_INSPECTOR");
        require(to == owner || to == payments[notaId].payer, "ONLY_TO_OWNER_OR_SENDER");
        return 0;
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/
    ) external view override onlyRegistrar {
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payments[tokenId];

        return (
                string(
                    abi.encodePacked(
                        ',{"trait_type":"Inspector","value":"',
                        Strings.toHexString(payment.inspector),
                        '"},{"trait_type":"Payer","value":"',
                        Strings.toHexString(payment.payer),
                        '"}'
                    )
                ), 
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        payment.imageURI, 
                        '","name":"Reversible Release Nota #',
                        Strings.toHexString(tokenId),
                        '","external_url":"', 
                        payment.external_url,
                        '","description":"The Reversible Release module allows the payer to choose the inspector who is then allowed to release the escrowed amount to the owner OR back to the payer."'
                    )
                )
            );
    }
}
