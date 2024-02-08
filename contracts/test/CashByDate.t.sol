// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import {CashByDate} from "../src/modules/CashByDate.sol";
import {RegistrarTest} from "./Registrar.t.sol";

contract CashByDateTest is RegistrarTest {
    CashByDate public CASH_BY_DATE;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
        CASH_BY_DATE = new CashByDate(address(REGISTRAR));
        vm.label(address(CASH_BY_DATE), "CashByDate");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) internal returns (uint256) {
        // TODO module specific state testing
        
        _registrarWriteAssumptions(caller, escrowed, instant, owner); // no address(0) and !registrar and !testingcontract

        _registrarModuleWhitelistToggleHelper(CASH_BY_DATE, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));

        bytes memory initData = abi.encode(
            1 days, // Cash By Date
            "ipfs://QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // externalURI
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png" // imageURI
        );
        uint256 notaId = _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, CASH_BY_DATE, initData);
        
        // TODO module specific state testing

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
        address to
    ) public {
        vm.assume(writer != owner);
        vm.assume(writer != fakeTransferer && fakeTransferer != owner);
        uint256 notaId = _setupThenWrite(writer, escrowed, instant, owner);
        
        _registrarTransferAddressAssumptions(writer, owner, to);  // Put this before write?
        _registrarTransferApprovedAssumptions(owner, owner, notaId);
        _registrarTransferHelper(fakeTransferer, owner, to, notaId);    
    }

    function testCashOwner(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner);

        vm.warp(1 days);
        _registrarCashHelper(owner, notaId, cashAmount, owner, abi.encode(""));
    }

    function testCashSender(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner);

        vm.warp(1 days + 1);
        _registrarCashHelper(owner, notaId, cashAmount, caller, abi.encode(""));
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

        vm.warp(1 days);
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

        vm.warp(1 days);
        _registrarCashHelper(owner, notaId, cashAmount, owner, abi.encode(""));
    }

    function testFailCashTo(
        address payer,
        uint256 escrowed,
        address owner,
        address fakeCasher,
        uint256 cashAmount,
        uint256 random
    ) public {
        vm.assume(fakeCasher != owner);
        uint256 notaId = _setupThenWrite(payer, escrowed, 0, owner);

        vm.warp(random);
        _registrarCashHelper(fakeCasher, notaId, cashAmount, fakeCasher, abi.encode(""));
    }

    function testFailCashOwner(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner);

        vm.warp(1 days + 1);
        _registrarCashHelper(owner, notaId, cashAmount, owner, abi.encode(""));
    }

    function testFailCashSender(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner);

        vm.warp(1 days);
        _registrarCashHelper(owner, notaId, cashAmount, caller, abi.encode(""));
    }
}