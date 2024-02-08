// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import {SimpleCash} from "../src/modules/SimpleCash.sol";
import {RegistrarTest} from "./Registrar.t.sol";

// TODO add fail tests
contract SimpleCashTest is RegistrarTest {
    SimpleCash public SIMPLE_CASH;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
        SIMPLE_CASH = new SimpleCash(address(REGISTRAR));
        vm.label(address(SIMPLE_CASH), "SimpleCash");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) internal returns (uint256) {
        _registrarWriteAssumptions(caller, escrowed, instant, owner); // !address(0) && !registrar/testingcontract && escrow<totalSupply

        _registrarModuleWhitelistToggleHelper(SIMPLE_CASH, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));

        bytes memory initData = abi.encode(
            "ipfs://QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // externalURI
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png" // imageURI
        );

        uint256 notaId = _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, SIMPLE_CASH, initData);

        return notaId;
    }

    function testWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        _setupThenWrite(caller, escrowed, instant, owner);
    }

    function testTransfer(
        address writer,
        uint256 escrowed,
        uint256 instant,
        address owner, 
        address newOwner
    ) public {
        vm.assume(writer != owner);
        uint256 notaId = _setupThenWrite(writer, escrowed, instant, owner);
        
        _registrarTransferAddressAssumptions(writer, owner, newOwner);  // Put this before write?
        _registrarTransferApprovedAssumptions(owner, owner, notaId);
        _registrarTransferHelper(
            owner,  // transfer caller
            owner, 
            newOwner, 
            notaId
        );
    }

    function testFailTransfer(
        address writer,
        address fakeTransferer,
        uint256 escrowed,
        uint256 instant,
        address owner, 
        address newOwner
    ) public {
        vm.assume(writer != owner);
        vm.assume(writer != fakeTransferer && fakeTransferer != owner);
        uint256 notaId = _setupThenWrite(writer, escrowed, instant, owner);
        
        _registrarTransferAddressAssumptions(writer, owner, newOwner);  // Put this before write?
        _registrarTransferApprovedAssumptions(owner, owner, notaId);
        _registrarTransferHelper(fakeTransferer, owner, newOwner, notaId);
    }

    function testCash(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner);

        _registrarCashHelper(owner, notaId, cashAmount, owner, abi.encode(""));
    }

    function testFailCashId(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount,
        uint256 random
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner);

        _registrarCashHelper(owner, notaId + random + 1, cashAmount, owner, abi.encode(""));
    }

    function testFailCashAmount(
        address payer,
        uint256 escrowed,
        address owner,
        uint256 cashAmount
    ) public {
        vm.assume(cashAmount > escrowed);
        uint256 notaId = _setupThenWrite(payer, escrowed, 0, owner);

        _registrarCashHelper(owner, notaId, cashAmount, owner, abi.encode(""));
    }

    function testFailCashTo(
        address payer,
        uint256 escrowed,
        address owner,
        address fakeCasher,
        uint256 cashAmount
    ) public {
        vm.assume(fakeCasher != owner);
        uint256 notaId = _setupThenWrite(payer, escrowed, 0, owner);

        _registrarCashHelper(fakeCasher, notaId, cashAmount, fakeCasher, abi.encode("")); // 
    }
}