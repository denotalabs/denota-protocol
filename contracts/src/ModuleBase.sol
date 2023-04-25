// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {DataTypes} from "./libraries/DataTypes.sol";
import {ICheqModule} from "./interfaces/ICheqModule.sol";
import {IRegistrarGov} from "./interfaces/IRegistrarGov.sol";

abstract contract ModuleBase is ICheqModule {
    address public immutable REGISTRAR;
    mapping(address => mapping(address => uint256)) public revenue; // rewardAddress => token => rewardAmount
    mapping(address => DataTypes.WTFCFees) public dappOperatorFees;
    uint256 internal constant BPS_MAX = 10_000;
    string public _URI;

    event ModuleBaseConstructed(address indexed registrar, uint256 timestamp);

    error FeeTooHigh();
    error NotRegistrar();
    error InitParamsInvalid();

    modifier onlyRegistrar() {
        if (msg.sender != REGISTRAR) revert NotRegistrar();
        _;
    }

    constructor(address registrar, DataTypes.WTFCFees memory _fees) {
        if (registrar == address(0)) revert InitParamsInvalid();
        if (BPS_MAX < _fees.writeBPS) revert FeeTooHigh();
        if (BPS_MAX < _fees.transferBPS) revert FeeTooHigh();
        if (BPS_MAX < _fees.fundBPS) revert FeeTooHigh();
        if (BPS_MAX < _fees.cashBPS) revert FeeTooHigh();

        REGISTRAR = registrar;
        dappOperatorFees[msg.sender] = _fees;

        emit ModuleBaseConstructed(registrar, block.timestamp);
    }

    function setFees(DataTypes.WTFCFees memory _fees) public {
        dappOperatorFees[msg.sender] = _fees;
    }

    function takeReturnFee(
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

    function processWrite(
        address caller,
        address owner,
        uint256 cheqId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata writeData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(writeData, (address));
        // Add module logic here
        return takeReturnFee(currency, escrowed + instant, dappOperator, 0);
    }

    function processTransfer(
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
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(transferData, (address));
        // Add module logic here
        return takeReturnFee(currency, escrowed, dappOperator, 1);
    }

    function processFund(
        address caller,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata fundData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(fundData, (address));
        // Add module logic here
        return takeReturnFee(cheq.currency, amount + instant, dappOperator, 2);
    }

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 amount,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata cashData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(cashData, (address));
        // Add module logic here
        return takeReturnFee(cheq.currency, amount, dappOperator, 3);
    }

    function processApproval(
        address caller,
        address owner,
        address to,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes memory initData
    ) external virtual override onlyRegistrar {
        // Add module logic here
    }

    function processTokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        return string(abi.encodePacked(_URI, tokenId));
    }

    function getFees(
        address dappOperator
    ) public view virtual returns (DataTypes.WTFCFees memory) {
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
