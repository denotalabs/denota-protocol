// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Noop} from "../src/modules/Noop.sol";
import {RegistrarTest} from "./Registrar.t.sol";

// TODO test when Nota owner is NotaRegistrar
contract NoopTest is RegistrarTest {
    Noop public NOOP;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
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
        bytes memory moduleBytes
    ) internal returns(uint256 notaId){
        _writeNoopAssumptions(caller, escrowed, instant, owner);

        _registrarModuleWhitelistToggleHelper(NOOP, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));
        notaId = _registrarWriteHelper(
            caller, 
            address(DAI), // currency
            escrowed, 
            instant,
            owner, 
            NOOP, // module
            moduleBytes
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
        vm.assume(caller != owner && owner != address(0) && to != address(0) && owner != to);  // Doesn't allow transfer to the zero address
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner, "");
        
        // TODO: test with an approved address
        _registrarTransferHelper(owner, owner, to, notaId); // NOTE: `caller` parameter must be owner or approved
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

        // Give more tokens for funding
        _tokenFundAddressApproveAddress(caller, DAI, fundEscrow + fundInstant, address(REGISTRAR));
        _registrarFundHelper(caller, notaId, fundEscrow, fundInstant, abi.encode(""));
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

        _registrarCashHelper(caller, notaId, cashAmount, owner, abi.encode(""));
    }
}