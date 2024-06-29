// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin/utils/Strings.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {RegistrarTest} from "./Registrar.t.sol";
import {IHooks} from "../src/interfaces/IHooks.sol";

abstract contract BaseHook is IHooks {
    address public immutable REGISTRAR;

    event HookBaseConstructed(address indexed registrar, uint256 timestamp);

    error NotRegistrar();
    error InitParamsInvalid();

    modifier onlyRegistrar() {
        if (msg.sender != REGISTRAR) revert NotRegistrar();
        _;
    }

    constructor(address registrar) {
        if (registrar == address(0)) revert InitParamsInvalid();
        REGISTRAR = registrar;
        emit HookBaseConstructed(registrar, block.timestamp);
    }

    function beforeWrite(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        return 0;
    }

    function beforeTransfer(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        return 0;
    }

    function beforeFund(
        address /*caller*/,
        NotaState calldata /*nota*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        return 0;
    }

    function beforeCash(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/,
        uint256 /*amount*/,
        bytes calldata /*hookData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        return 0;
    }

    function beforeApprove(
        address /*caller*/,
        NotaState calldata /*nota*/,
        address /*to*/
    ) external virtual override onlyRegistrar returns (uint256) {
        return 0;
    }

    function beforeBurn(
        address /*caller*/,
        NotaState calldata /*nota*/
    ) external virtual override onlyRegistrar {
    }

    function beforeTokenURI(
        uint256 /*notaId*/
    ) external view virtual override returns (string memory, string memory) {
        return ("", "");
    }
}

contract Noop is BaseHook {
    constructor(address registrar) BaseHook(registrar) {}
}

contract NoopTest is RegistrarTest {
    Noop public NOOP;

    function setUp() public override {
        super.setUp();
        NOOP = new Noop(address(REGISTRAR));
        vm.label(address(NOOP), "Noop");
    }

    function _writeNoopAssumptions(
        address caller,
        uint256 escrow,
        uint256 instant,
        address owner
    ) internal {
        vm.assume(caller != address(0) && caller != owner && owner != address(0));
        vm.assume(owner != address(REGISTRAR) && caller != address(REGISTRAR));
        vm.assume((escrow/2 + instant/2) < TOKENS_CREATED / 2);

        vm.label(caller, "Caller");
        vm.label(owner, "Nota Owner");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        bytes memory hookData
    ) internal returns(uint256 notaId) {
        _writeNoopAssumptions(caller, escrowed, instant, owner);

        _registrarHookWhitelistToggleHelper(NOOP, false);
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));
        notaId = _registrarWriteHelper(
            caller, 
            address(DAI),
            escrowed, 
            instant,
            owner, 
            NOOP,
            hookData
        );
    }

    function testWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        _setupThenWrite(caller, escrowed, instant, owner, "");
    }

    function testTransfer(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner, 
        address to
    ) public {
        vm.assume(caller != owner && owner != address(0) && to != address(0) && owner != to);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner, "");
        
        _registrarTransferHelper(owner, owner, to, notaId);
    }

    function testFund(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        uint256 fundEscrow,
        uint256 fundInstant
    ) public {
        vm.assume((escrowed/2 + instant/2) < TOKENS_CREATED / 4);
        vm.assume((fundEscrow/2 + fundInstant/2) < TOKENS_CREATED / 4);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner, "");

        _tokenFundAddressApproveAddress(caller, DAI, fundEscrow + fundInstant, address(REGISTRAR));
        _registrarFundHelper(caller, notaId, fundEscrow, fundInstant, "");
    }

    function testCash(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        uint256 cashAmount
    ) public {
        vm.assume(cashAmount <= escrowed);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner, "");

        _registrarCashHelper(caller, notaId, cashAmount, owner, "");
    }

    function testApprove(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address to
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner, "");

        _registrarApproveHelper(owner, to, notaId);
    }

    function testBurn(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner, "");
        
        _registrarBurnHelper(owner, notaId);
    }
}