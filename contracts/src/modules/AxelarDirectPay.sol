// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import {BridgeReceiver} from "../axelar/BridgeReceiver.sol";

/**
 * @title AxelarDirectPay
 * @dev Module that allows direct payments to be made on one chain and the Nota being minted on the other (this) chain.
 */
contract AxelarDirectPay is ModuleBase {
    BridgeReceiver private bridgeReceiver;

    struct Payment {
        uint256 amount; // Value that was sent on the other chain
        uint256 sourceChain;
        string imageURI;
        string memoHash;
        address sender;
    }
    mapping(uint256 => Payment) public payInfo;

    event PaymentCreated(
        uint256 notaId,
        string memoHash,
        uint256 amount,
        address creditor,
        address debtor,
        uint256 sourceChainId,
        uint256 destChainId
    );
    /**
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
     */
    error OnlyAxelar();
    error OnlyMinting();
    error AmountZero();
    error AddressZero();
    error Disallowed();
    error OnlyOwner();
    error OnlyOwnerOrApproved();

    constructor(
        address registrar,
        DataTypes.WTFCFees memory _fees,
        string memory __baseURI,
        BridgeReceiver _bridgeReceiver
    ) ModuleBase(registrar, _fees) {
        _URI = __baseURI;
        bridgeReceiver = _bridgeReceiver;
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
        if (owner == address(0)) revert AddressZero();
        if (escrowed + instant != 0) revert OnlyMinting();

        (
            uint256 amount, // Amount that was sent on the other chain
            uint256 sourceChain,
            address dappOperator,
            string memory imageURI,
            string memory memoHash,
            address sender
        ) = abi.decode(
                initData,
                (uint256, uint256, address, string, string, address)
            );
        if (amount == 0) revert AmountZero();

        payInfo[notaId] = Payment(
            amount,
            sourceChain,
            imageURI,
            memoHash,
            sender
        );

        _logPaymentCreated(notaId, owner, sourceChain);

        return takeReturnFee(currency, instant, dappOperator, 0);
    }

    function _logPaymentCreated(
        uint256 notaId,
        address creditor,
        uint256 sourceChain
    ) private {
        emit PaymentCreated(
            notaId,
            payInfo[notaId].memoHash,
            payInfo[notaId].amount,
            creditor,
            payInfo[notaId].sender,
            sourceChain,
            block.chainid
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
    ) public override onlyRegistrar returns (uint256) {
        if (caller != owner && caller != approved) revert OnlyOwnerOrApproved();
        return
            takeReturnFee(currency, escrowed, abi.decode(data, (address)), 1);
    }

    function processFund(
        address /*caller*/,
        address /*owner*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        uint256 /*notaId*/,
        DataTypes.Nota calldata /*nota*/,
        bytes calldata /*initData*/
    ) public view override onlyRegistrar returns (uint256) {
        revert Disallowed();
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
