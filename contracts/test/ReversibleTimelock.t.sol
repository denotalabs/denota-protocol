// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import {ReversibleTimelock} from "../src/modules/ReversibleTimelock.sol";
import {RegistrarTest} from "./Registrar.t.sol";

contract ReversibleTimelockTest is RegistrarTest {
    ReversibleTimelock public REVERSIBLE_TIMELOCK;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
        REVERSIBLE_TIMELOCK = new ReversibleTimelock(address(REGISTRAR));
        vm.label(address(REVERSIBLE_TIMELOCK), "ReversibleTimelock");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address inspector
    ) internal returns (uint256) {
        vm.assume(inspector != address(0));
        _registrarWriteAssumptions(caller, escrowed, instant, owner); // no address(0) and not registrar or testing contract

        _registrarModuleWhitelistToggleHelper(REVERSIBLE_TIMELOCK, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));

        bytes memory initData = abi.encode(
            inspector,
            1 days,  // 1 day inspection period
            "ipfs://QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv",
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png"
        );
        uint256 notaId = _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, REVERSIBLE_TIMELOCK, initData);

        return notaId;
    }

    function testWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address inspector
    ) public {
        vm.assume(inspector != address(0));

        _setupThenWrite(caller, escrowed, instant, owner, inspector);
    }

    function testTransfer(
        address writer,
        uint256 escrowed,
        uint256 instant,
        address owner, 
        address newOwner,
        address inspector
    ) public {
        vm.assume(writer != owner);
        vm.assume(inspector != address(0));
        uint256 notaId = _setupThenWrite(writer, escrowed, instant, owner, inspector);
        
        _registrarTransferAddressAssumptions(writer, owner, newOwner);  // Put this before write?
        _registrarTransferApprovedAssumptions(owner, owner, notaId);
        _registrarTransferHelper(
            owner,  // transfer caller
            owner,  // from
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
        address to,
        address inspector
    ) public {
        vm.assume(writer != owner);
        vm.assume(writer != fakeTransferer && fakeTransferer != owner && fakeTransferer != address(0));
        uint256 notaId = _setupThenWrite(writer, escrowed, instant, owner, inspector);
        
        _registrarTransferAddressAssumptions(writer, owner, to);  // Put this before write?
        _registrarTransferApprovedAssumptions(owner, owner, notaId);
        _registrarTransferHelper(fakeTransferer, owner, to, notaId);
    }

    function testCashOwner(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount,
        address inspector
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner, inspector);

        vm.warp(1 days);
        _registrarCashHelper(inspector, notaId, cashAmount, owner, abi.encode(""));
    }

    function testCashSender(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount,
        address inspector
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner, inspector);

        vm.warp(1 days - 1);
        _registrarCashHelper(inspector, notaId, cashAmount, caller, abi.encode(""));
    }

    function testFailCashId(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount,
        uint256 random,
        address inspector
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner, inspector);

        vm.warp(random);
        _registrarCashHelper(owner, notaId + random + 1, cashAmount, owner, abi.encode(""));
    }

    function testFailCashAmount(
        address payer,
        uint256 escrowed,
        address owner,
        uint256 cashAmount,
        address inspector,
        uint256 random
    ) public {
        vm.assume(cashAmount > escrowed);
        uint256 notaId = _setupThenWrite(payer, escrowed, 0, owner, inspector);

        vm.warp(random);
        _registrarCashHelper(owner, notaId, cashAmount, owner, abi.encode(""));
    }

    function testFailCashTo(
        address payer,
        uint256 escrowed,
        address owner,
        address fakeCasher,
        uint256 cashAmount,
        address inspector,
        uint256 random
    ) public {
        vm.assume(fakeCasher != owner);
        uint256 notaId = _setupThenWrite(payer, escrowed, 0, owner, inspector);

        vm.warp(random);
        _registrarCashHelper(fakeCasher, notaId, cashAmount, fakeCasher, abi.encode(""));
    }

    function testFailCashOwner(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount,
        address inspector
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner, inspector);

        vm.warp(1 days - 1);
        _registrarCashHelper(inspector, notaId, cashAmount, owner, abi.encode(""));
    }

    function testFailCashSender(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount,
        address inspector
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner, inspector);

        vm.warp(1 days);
        _registrarCashHelper(inspector, notaId, cashAmount, caller, abi.encode(""));
    }

    function testFailCashNotInspectorToSender(
        address caller,
        uint256 escrowed,
        address owner,
        uint256 cashAmount,
        address inspector,
        address randomAddress
    ) public {
        vm.assume(cashAmount <= escrowed);
        vm.assume(caller != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, 0, owner, inspector);

        vm.warp(1 days - 1);
        _registrarCashHelper(randomAddress, notaId, cashAmount, caller, abi.encode(""));
    }
}