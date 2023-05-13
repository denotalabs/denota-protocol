// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "kleros/IArbitrable.sol";
import "kleros/IArbitrator.sol";
import "kleros/erc-1497/IEvidence.sol";

import {AxelarExecutable} from "axelarnetwork/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "axelarnetwork/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelarnetwork/interfaces/IAxelarGasService.sol";

contract DenotaArbitrable is IArbitrable, IEvidence, AxelarExecutable {
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

    struct Dispute {
        uint256 txID;
        IArbitrator arbitrator;
        string destinationChain;
        string destinationAddress;
    }

    Dispute[] public txs;

    mapping(uint256 => Dispute) disputeIDtoDispute;

    IAxelarGasService public immutable gasReceiver; // The same on all chains (minus Aurora)

    constructor(
        address gateway_,
        address gasReceiver_
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }

    function createDispute(
        uint256 _txID, // notaID on polygon
        IArbitrator arbitrator,
        string calldata destinationChain,
        string calldata destinationAddress
    ) public payable {
        // TODO: who should pay for disputes: payer or payee? who should be able to create them?

        // TODO: do we need to Polygon know that a dispute was created? What if the payment is released before the ruling?
        uint256 disputeID = arbitrator.createDispute{value: msg.value}(
            numberOfRulingOptions,
            ""
        );

        disputeIDtoDispute[disputeID] = Dispute({
            txID: _txID,
            arbitrator: arbitrator,
            destinationChain: destinationChain,
            destinationAddress: destinationAddress
        });
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        // Send ruling to polygon via Axelar
        Dispute storage dispute = disputeIDtoDispute[_disputeID];

        if (msg.sender != address(dispute.arbitrator)) {
            revert NotArbitrator();
        }

        bytes memory payload = abi.encode(block.chainid, dispute.txID, _ruling);

        if (msg.value > 0) {
            // Question: How to determine how much gas to pay??
            gasReceiver.payNativeGasForContractCall{value: msg.value}(
                address(this),
                dispute.destinationChain,
                dispute.destinationAddress,
                payload,
                msg.sender
            );
        }

        gateway.callContract(
            dispute.destinationChain,
            dispute.destinationAddress,
            payload
        );

        emit Ruling(dispute.arbitrator, _disputeID, _ruling);
    }

    function submitEvidence(
        uint256 _disputeID,
        string memory _evidence
    ) public {
        Dispute storage dispute = txs[_disputeID];

        // TODO: restrict to only payer/payee

        emit Evidence(dispute.arbitrator, dispute.txID, msg.sender, _evidence);
    }
}
