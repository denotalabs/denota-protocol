// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.14;

import "openzeppelin/token/ERC20/IERC20.sol";
import {AxelarExecutable} from "axelarnetwork/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "axelarnetwork/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelarnetwork/interfaces/IAxelarGasService.sol";
import "../NotaRegistrar.sol";

/**
 * @title BridgeSender
 * @dev
 */
contract BridgeSender is AxelarExecutable {
    event PaymentCreated(
        string memoHash,
        uint256 amount,
        uint256 timestamp,
        address creditor,
        address debtor,
        uint256 chainId,
        string destinationChain
    );

    IAxelarGasService public immutable gasReceiver; // The same on all chains (minus Aurora)
    error SendFailed();

    constructor(
        address gateway_,
        address gasReceiver_
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
    }

    function createRemoteNota(
        address token,
        uint256 amount,
        address owner,
        string calldata memoURI_,
        string calldata imageURI_,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external payable {
        if (token == address(0)) {
            require(msg.value >= amount, "Incorrect value");
            (bool sent, ) = owner.call{value: amount}("");
            if (!sent) revert SendFailed();
        } else {
            require(IERC20(token).transfer(owner, amount), "Transfer failed");
        }

        // write data
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

        emit PaymentCreated(
            memoURI_,
            amount,
            block.timestamp,
            owner,
            msg.sender,
            block.chainid,
            destinationChain
        );
    }
}
