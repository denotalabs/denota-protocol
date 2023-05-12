// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {ICheqModule} from "../interfaces/ICheqModule.sol";
import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

/**
 * Note: Only payments, allows sender to choose when to release and whether to reverse (assuming it's not released yet)
 */
contract KlerosEscrow is ModuleBase {
    struct Payment {
        address payer;
        address payee;
        uint256 escrowed;
        uint256 timelockEnd;
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
    error OnlyOwnerOrApproved();

    address public klerosReceiver;

    constructor(
        address registrar,
        DataTypes.WTFCFees memory _fees,
        string memory __baseURI,
        address _klerosReceiver
    ) ModuleBase(registrar, _fees) {
        _URI = __baseURI;
        klerosReceiver = _klerosReceiver;
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
            uint256 timelockEnd,
            address payee,
            address dappOperator,
            bytes32 memoHash
        ) = abi.decode(initData, (uint256, address, address, bytes32));
        require((caller != owner) && (owner != address(0)), "Invalid Params");

        payments[cheqId].payer = caller;
        payments[cheqId].payee = owner;
        payments[cheqId].escrowed = escrowed;
        payments[cheqId].memoHash = memoHash;
        payments[cheqId].timelockEnd = timelockEnd;

        return takeReturnFee(currency, escrowed + instant, dappOperator, 0);
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
        require(
            caller == owner || caller == approved,
            "Only owner or approved"
        );
        return takeReturnFee(currency, 0, abi.decode(data, (address)), 1);
    }

    function processFund(
        address, // caller,
        address, // owner,
        uint256, // amount,
        uint256, // instant,
        uint256, // cheqId,
        DataTypes.Cheq calldata, // cheq,
        bytes calldata // initData
    ) external view override onlyRegistrar returns (uint256) {
        require(false, "");
        return 0;
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
        if (caller == payments[cheqId].payee) {
            require(payments[cheqId].timelockEnd < block.timestamp, "TIMELOCK");
        } else if (caller == payments[cheqId].payer) {
            require(
                to == payments[cheqId].payee,
                "Payer can only release to payee"
            );
        } else {
            require(caller == klerosReceiver, "KlerosReceiver only");
        }
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
        address to,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes memory initData
    ) external override onlyRegistrar {}

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        return
            bytes(_URI).length > 0
                ? string(abi.encodePacked(',"external_url":', _URI, tokenId))
                : "";

        // return string(abi.encode(_URI, payments[tokenId].memoHash));
    }

    function processRuling(
        uint256 notaId,
        uint256 _ruling
    ) external view returns (address to, uint256 amount) {
        // TODO: have the registrar call this directly

        // TODO: handle 0 (RefusedToArbitrate)
        if (_ruling == 1) {
            // Payer wins
            return (payments[notaId].payer, payments[notaId].escrowed);
        } else if (_ruling == 2) {
            // Payee win
            return (payments[notaId].payee, payments[notaId].escrowed);
        }
        revert("Ruling not recognized");
    }
}
