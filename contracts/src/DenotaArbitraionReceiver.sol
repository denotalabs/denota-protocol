pragma solidity >=0.8.14;

import "openzeppelin/token/ERC20/IERC20.sol";
import {AxelarExecutable} from "axelarnetwork/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "axelarnetwork/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelarnetwork/interfaces/IAxelarGasService.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import "./CheqRegistrar.sol";
import {KlerosEscrow} from "./modules/KlerosEscrow.sol";

contract DenotaArbitraionReceiver is AxelarExecutable {
    IAxelarGasService public immutable gasReceiver;
    CheqRegistrar public cheq;
    KlerosEscrow public klerosEscrowModule;

    error OnlyGateway();

    constructor(
        address gateway_,
        address gasReceiver_,
        CheqRegistrar _cheq,
        KlerosEscrow _klerosEscrowModule
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
        cheq = _cheq;
        klerosEscrowModule = _klerosEscrowModule;
    }

    function _execute(
        string calldata /*sourceChain_*/,
        string calldata /*sourceAddress_*/,
        bytes calldata payload_
    ) internal override {
        (uint256 sourceChain, uint256 notaId, uint256 _ruling) = abi.decode(
            payload_,
            (uint256, uint256, uint256)
        );

        bytes memory modulePayload = abi.encode(msg.sender);

        (address to, uint256 amount) = klerosEscrowModule.processRuling(
            notaId,
            _ruling
        );

        cheq.cash(notaId, amount, to, modulePayload);
    }
}
