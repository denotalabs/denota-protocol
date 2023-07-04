// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "kleros/IArbitrable.sol";
import "kleros/IArbitrator.sol";
import "kleros/erc-1497/IEvidence.sol";

import {AxelarExecutable} from "axelarnetwork/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "axelarnetwork/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelarnetwork/interfaces/IAxelarGasService.sol";
import {KlerosEscrow} from "./modules/KlerosEscrow.sol";
import "./CheqRegistrar.sol";

// Should this be part of the Kleros module
contract DenotaArbitrable is IArbitrable, IEvidence {
    CheqRegistrar public cheq;
    KlerosEscrow public klerosEscrowModule;
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

    constructor(CheqRegistrar _cheq, KlerosEscrow _klerosEscrowModule) {
        cheq = _cheq;
        klerosEscrowModule = _klerosEscrowModule;
    }

    function createDispute(
        uint256 _txID, // notaID on polygon
        IArbitrator arbitrator,
        string calldata destinationChain,
        string calldata destinationAddress
    ) public payable {
        // TODO: who should pay for disputes: payer or payee? who should be able to create them?

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

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        DisputeInfo storage dispute = disputeIDtoDispute[_disputeID];

        if (msg.sender != address(dispute.arbitrator)) {
            revert NotArbitrator();
        }

        (address to, uint256 amount) = klerosEscrowModule.processRuling(
            dispute.txID,
            _ruling
        );

        bytes memory modulePayload = abi.encode(msg.sender);

        cheq.cash(dispute.txID, amount, to, modulePayload);

        emit Ruling(dispute.arbitrator, _disputeID, _ruling);
    }

    function submitEvidence(
        uint256 _disputeID,
        string memory _evidence
    ) public {
        DisputeInfo storage dispute = txs[_disputeID];

        // TODO: restrict to only payer/payee

        emit Evidence(dispute.arbitrator, dispute.txID, msg.sender, _evidence);
    }
}
