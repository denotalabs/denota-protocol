pragma solidity >=0.8.14;

import "openzeppelin/token/ERC20/IERC20.sol";
import {AxelarExecutable} from "axelarnetwork/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "axelarnetwork/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelarnetwork/interfaces/IAxelarGasService.sol";
import "../CheqRegistrar.sol";

contract BridgeReceiver is AxelarExecutable {
    IAxelarGasService public immutable gasReceiver;
    CheqRegistrar public cheq;
    address public directPayAxelar;

    error OnlyGateway();

    constructor(
        address gateway_,
        address gasReceiver_,
        CheqRegistrar _cheq,
        address _directPayAxelar
    ) AxelarExecutable(gateway_) {
        gasReceiver = IAxelarGasService(gasReceiver_);
        cheq = _cheq;
        directPayAxelar = _directPayAxelar;
    }

    function _execute(
        string calldata /*sourceChain_*/,
        string calldata /*sourceAddress_*/,
        bytes calldata payload_
    ) internal override {
        (
            uint256 sourceChain,
            uint256 amount,
            address _token,
            address owner,
            address sender,
            string memory imageURI,
            string memory memoHash
        ) = abi.decode(
                payload_,
                (uint256, uint256, address, address, address, string, string)
            );

        bytes memory modulePayload = abi.encode(
            amount,
            sourceChain,
            address(cheq),
            imageURI,
            memoHash,
            sender
        );

        cheq.write(_token, 0, 0, owner, directPayAxelar, modulePayload);
    }
}
