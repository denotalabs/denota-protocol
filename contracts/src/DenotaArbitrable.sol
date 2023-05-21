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

    error NotArbitrator();

    struct DisputeInfo {
        uint256 txID;
        IArbitrator arbitrator;
        string destinationChain;
        string destinationAddress;
        bool hasRuling;
        uint256 ruling;
    }

    DisputeInfo[] public txs;

    mapping(uint256 => DisputeInfo) disputeIDtoDispute;

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

        disputeIDtoDispute[disputeID] = DisputeInfo({
            txID: _txID,
            arbitrator: arbitrator,
            destinationChain: destinationChain,
            destinationAddress: destinationAddress,
            hasRuling: false,
            ruling: 0
        });
    }

    function bridgeRuling(uint256 _disputeID) public payable {
        DisputeInfo storage dispute = disputeIDtoDispute[_disputeID];
        require(dispute.hasRuling, "Disput not resolved");
        require(msg.value > 0, "Requires payment for bridge fees");

        // Send ruling to polygon via Axelar
        // TODO: Who should pay for bridging fees? Should we collect for a deposit for bridging fees from the payer/payee?

        bytes memory payload = abi.encode(
            block.chainid,
            dispute.txID,
            dispute.ruling
        );

        // Question: How to determine how much gas to pay??
        gasReceiver.payNativeGasForContractCall{value: msg.value}(
            address(this),
            dispute.destinationChain,
            dispute.destinationAddress,
            payload,
            msg.sender
        );

        gateway.callContract(
            dispute.destinationChain,
            dispute.destinationAddress,
            payload
        );
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        DisputeInfo storage dispute = disputeIDtoDispute[_disputeID];

        if (msg.sender != address(dispute.arbitrator)) {
            revert NotArbitrator();
        }

        bytes memory payload = abi.encode(block.chainid, dispute.txID, _ruling);

        // TODO: This needs to be called separately since rule is nonpayable
        // TODO: Figure out who calls the function/pays gas in that case

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
        DisputeInfo storage dispute = txs[_disputeID];

        // TODO: restrict to only payer/payee
        // Payer/payee information is on Polygon, how to bridge that over?

        emit Evidence(dispute.arbitrator, dispute.txID, msg.sender, _evidence);
    }
}
