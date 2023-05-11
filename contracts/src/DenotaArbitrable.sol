// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "kleros/IArbitrable.sol";
import "kleros/IArbitrator.sol";
import "kleros/erc-1497/IEvidence.sol";

import {AxelarExecutable} from "axelarnetwork/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "axelarnetwork/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelarnetwork/interfaces/IAxelarGasService.sol";

contract Escrow is IArbitrable, IEvidence, AxelarExecutable {
    enum Status {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
    }
    enum RulingOptions {
        RefusedToArbitrate,
        PayerWins,
        PayeeWins
    }
    uint256 constant numberOfRulingOptions = 2;

    error InvalidStatus();
    error ReleasedTooEarly();
    error NotPayer();
    error NotArbitrator();
    error ThirdPartyNotAllowed();
    error PayeeDepositStillPending();
    error ReclaimedTooLate();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);

    mapping(uint256 => IArbitrator) disputeIDtoArbitrator;

    IAxelarGasService public immutable gasReceiver; // The same on all chains (minus Aurora)

    constructor(
        address gateway_,
        address gasReceiver_
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }

    function createDispute(
        uint256 _txID,
        IArbitrator arbitrator
    ) public payable {
        // TODO: who should pay for disputes: payer or payee?

        uint256 disputeID = arbitrator.createDispute{value: msg.value}(
            numberOfRulingOptions,
            ""
        );
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        // Send ruling to polygon via Axelar

        bytes memory payload = abi.encode(
            block.chainid,
            amount,
            token,
            owner,
            msg.sender,
            imageURI_,
            memoURI_
        );

        if (msg.value > 0) {
            // Question: How to determine how much gas to pay??
            gasReceiver.payNativeGasForContractCall{value: msg.value - amount}(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
        }

        gateway.callContract(destinationChain, destinationAddress, payload);

        emit Ruling(_disputeID, _ruling);
    }

    function submitEvidence(uint256 _txID, string memory _evidence) public {}
}
