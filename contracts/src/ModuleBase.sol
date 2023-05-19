// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {ICheqModule} from "./interfaces/ICheqModule.sol";

abstract contract ModuleBase is ICheqModule {
    struct WTFCFees {
        uint256 writeBPS;
        uint256 transferBPS;
        uint256 fundBPS;
        uint256 cashBPS;
    }

    uint256 internal constant BPS_MAX = 10_000;
    address public immutable REGISTRAR;
    mapping(address => mapping(address => uint256)) public revenue; // rewardAddress => token => rewardAmount
    mapping(address => WTFCFees) public dappOperatorFees;

    error FeeTooHigh();
    error InitParamsInvalid();

    constructor(address registrar, WTFCFees memory _fees) {
        if (registrar == address(0)) revert InitParamsInvalid();
        if (BPS_MAX < _fees.writeBPS) revert FeeTooHigh();
        if (BPS_MAX < _fees.transferBPS) revert FeeTooHigh();
        if (BPS_MAX < _fees.fundBPS) revert FeeTooHigh();
        if (BPS_MAX < _fees.cashBPS) revert FeeTooHigh();

        REGISTRAR = registrar;
        dappOperatorFees[msg.sender] = _fees;

        emit ModuleBaseConstructed(registrar, block.timestamp);
    }

    function setFees(WTFCFees memory _fees) public {
        dappOperatorFees[msg.sender] = _fees;
    }

    function _takeReturnFee(
        address currency,
        uint256 amount,
        address dappOperator,
        uint8 _WTFC
    ) internal returns (uint256 fee) {
        if (_WTFC == 0) {
            fee = dappOperatorFees[dappOperator].writeBPS;
        } else if (_WTFC == 1) {
            fee = dappOperatorFees[dappOperator].transferBPS;
        } else if (_WTFC == 2) {
            fee = dappOperatorFees[dappOperator].fundBPS;
        } else if (_WTFC == 3) {
            fee = dappOperatorFees[dappOperator].cashBPS;
        } else {
            revert("");
        }
        // TODO ensure this doesn't overflow
        fee = (amount * fee) / BPS_MAX;
        revenue[dappOperator][currency] += fee;
    }

    function _processWrite(
        address caller,
        address owner,
        uint256 cheqId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata writeData
    ) internal virtual override returns (uint256) {
        address dappOperator = abi.decode(writeData, (address));
        // Add module logic here
        return takeReturnFee(currency, escrowed + instant, dappOperator, 0);
    }

    function _processTransfer(
        address caller,
        address approved,
        address owner,
        address from,
        address to,
        uint256 cheqId,
        address currency,
        uint256 escrowed,
        uint256 createdAt,
        bytes calldata transferData
    ) internal virtual override returns (uint256) {
        address dappOperator = abi.decode(transferData, (address));
        // Add module logic here
        require(
            msg.sender == owner || msg.sender == approved,
            "Sender not Owner or approved"
        );
        return takeReturnFee(currency, escrowed, dappOperator, 1);
    }

    function _processFund(
        address caller,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata fundData
    ) internal virtual override returns (uint256) {
        address dappOperator = abi.decode(fundData, (address));
        // Add module logic here
        return takeReturnFee(cheq.currency, amount + instant, dappOperator, 2);
    }

    function _processCash(
        address caller,
        address owner,
        address to,
        uint256 amount,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata cashData
    ) internal virtual override returns (uint256) {
        address dappOperator = abi.decode(cashData, (address));
        // Add module logic here
        require(msg.sender == owner, "Casher not Owner");
        return takeReturnFee(cheq.currency, amount, dappOperator, 3);
    }

    function _processApproval(
        address caller,
        address owner,
        address to,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes memory initData
    ) internal virtual override {
        // Add module logic here
    }

    function _processTokenURI(
        uint256 tokenId
    ) internal view virtual override returns (string memory) {
        return string(abi.encodePacked(_URI, tokenId));
    }

    function getFees(
        address dappOperator
    ) public view virtual returns (WTFCFees memory) {
        return dappOperatorFees[dappOperator];
    }

    function withdrawFees(address token) public {
        uint256 payoutAmount = revenue[msg.sender][token];
        revenue[msg.sender][token] = 0;
        if (payoutAmount > 0)
            IRegistrarGov(REGISTRAR).moduleWithdraw(
                token,
                payoutAmount,
                msg.sender
            );
    }
}
