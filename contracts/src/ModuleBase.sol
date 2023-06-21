// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {DataTypes} from "./libraries/DataTypes.sol";
import {INotaModule} from "./interfaces/INotaModule.sol";
import {INotaRegistrar} from "./interfaces/INotaRegistrar.sol";
import {NotaEncoding} from "./libraries/Base64Encoding.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Strings.sol";


// TODO use uniswap V4 fee taking model
// TODO have inheritence for URIs
// TODO how to handle erc721 inheritence
abstract contract ModuleBase is INotaModule, NotaEncoding {
    using Strings for address;
    address public immutable REGISTRAR;
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

    constructor(address registrar) {
        if (registrar == address(0)) revert InitParamsInvalid();
        REGISTRAR = registrar;
        emit ModuleBaseConstructed(registrar, block.timestamp);
    }

    function processWrite(
        address caller,
        address owner,
        uint256 notaId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata writeData
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add module logic here
        return 0;
    }

    function processTransfer(
        address caller,
        address approved,
        address owner,
        address from,
        address to,
        uint256 notaId,
        address currency,
        uint256 escrowed,
        uint256 createdAt,
        bytes calldata transferData
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add module logic here
        return 0;
    }

    function processFund(
        address caller,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata fundData
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add module logic here
        return 0;
    }

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 amount,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata cashData
    ) external virtual override onlyRegistrar returns (uint256) {
        // Add module logic here
        return 0;
    }

    function processApproval(
        address caller,
        address owner,
        address to,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes memory initData
    ) external virtual override onlyRegistrar {
        // Add module logic here
    }

    function processTokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory, string memory) {
        return ("", "");
    }

    function getFees(
        address dappOperator
    ) public view virtual returns (DataTypes.WTFCFees memory) {
        return DataTypes.WTFCFees(0, 0, 0, 0);
    }
        function takeReturnFee(
        address currency,
        uint256 amount,
        address dappOperator,
        uint8 _WTFC
    ) internal returns (uint256 fee) { return 0;}

    // function withdrawFees(address token) public {
    //     uint256 payoutAmount = revenue[msg.sender][token];
    //     revenue[msg.sender][token] = 0;
    //     if (payoutAmount > 0)
    //         INotaRegistrar(REGISTRAR).moduleWithdraw(
    //             token,
    //             payoutAmount,
    //             msg.sender
    //         );
    // }
}

abstract contract OperatorFeeModuleBase is INotaModule, NotaEncoding {
    using Strings for address;
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
        uint256 notaId,
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
        uint256 notaId,
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
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata fundData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(fundData, (address));
        // Add module logic here
        return takeReturnFee(nota.currency, amount + instant, dappOperator, 2);
    }

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 amount,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata cashData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(cashData, (address));
        // Add module logic here
        return takeReturnFee(nota.currency, amount, dappOperator, 3);
    }

    function processApproval(
        address caller,
        address owner,
        address to,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes memory initData
    ) external virtual override onlyRegistrar {
        // Add module logic here
    }

    function processTokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory, string memory) {
        return ("", "");
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
            INotaRegistrar(REGISTRAR).moduleWithdraw(
                token,
                payoutAmount,
                msg.sender
            );
    }
}

abstract contract OwnerFeeModuleBase is INotaModule, Ownable, NotaEncoding {
    using Strings for address;
    address public immutable REGISTRAR;
    mapping(address => uint256) public revenue; // token => rewardAmount
    DataTypes.WTFCFees public  fees;
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
        fees = _fees;

        emit ModuleBaseConstructed(registrar, block.timestamp);
    }

    function setFees(DataTypes.WTFCFees memory _fees) public onlyOwner {
        fees = _fees;
    }

    function takeReturnFee(
        address currency,
        uint256 amount,
        uint8 _WTFC
    ) internal returns (uint256 fee) {
        if (_WTFC == 0) {
            fee = fees.writeBPS;
        } else if (_WTFC == 1) {
            fee = fees.transferBPS;
        } else if (_WTFC == 2) {
            fee = fees.fundBPS;
        } else if (_WTFC == 3) {
            fee = fees.cashBPS;
        } else {
            revert("");
        }
        // TODO ensure this doesn't overflow
        fee = (amount * fee) / BPS_MAX;
        revenue[currency] += fee;
    }

    function processWrite(
        address caller,
        address owner,
        uint256 notaId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata writeData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(writeData, (address));
        // Add module logic here
        return takeReturnFee(currency, escrowed + instant, 0);
    }

    function processTransfer(
        address caller,
        address approved,
        address owner,
        address from,
        address to,
        uint256 notaId,
        address currency,
        uint256 escrowed,
        uint256 createdAt,
        bytes calldata transferData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(transferData, (address));
        // Add module logic here
        return takeReturnFee(currency, escrowed, 1);
    }

    function processFund(
        address caller,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata fundData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(fundData, (address));
        // Add module logic here
        return takeReturnFee(nota.currency, amount + instant, 2);
    }

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 amount,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes calldata cashData
    ) external virtual override onlyRegistrar returns (uint256) {
        address dappOperator = abi.decode(cashData, (address));
        // Add module logic here
        return takeReturnFee(nota.currency, amount, 3);
    }

    function processApproval(
        address caller,
        address owner,
        address to,
        uint256 notaId,
        DataTypes.Nota calldata nota,
        bytes memory initData
    ) external virtual override onlyRegistrar {
        // Add module logic here
    }

    function processTokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory, string memory) {
        // Add module logic here
        return ("", "");
    }

    function getFees(
        address dappOperator
    ) public view virtual returns (DataTypes.WTFCFees memory) {
        return fees;
    }

    function withdrawFees(address token) public onlyOwner {
        uint256 payoutAmount = revenue[token];
        revenue[token] = 0;
        if (payoutAmount > 0)
            INotaRegistrar(REGISTRAR).moduleWithdraw(
                token,
                payoutAmount,
                msg.sender
            );
    }
}
