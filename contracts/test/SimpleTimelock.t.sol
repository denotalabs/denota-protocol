// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import {SimpleTimelock} from "../src/modules/SimpleTimelock.sol";
import {RegistrarTest} from "./Registrar.t.sol";

// TODO add fail tests
contract SimpleTimelockTest is RegistrarTest {
    SimpleTimelock public SIMPLE_TIMELOCK;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
        SIMPLE_TIMELOCK = new SimpleTimelock(address(REGISTRAR));
        vm.label(address(SIMPLE_TIMELOCK), "SimpleTimelock");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) internal returns (uint256) {
        // TODO module specific state testing
        
        _registrarWriteAssumptions(caller, escrowed, instant, owner); // no address(0) and !registrar and !testingcontract

        _registrarModuleWhitelistToggleHelper(SIMPLE_TIMELOCK, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));

        bytes memory initData = abi.encode(
            7 days, // duration
            "ipfs://QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // docHash
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png" // imageURI
        );
        uint256 notaId = _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, SIMPLE_TIMELOCK, initData);
        
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
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner, 
        address to
    ) public {
        vm.assume(caller != owner && owner != address(0) && to != address(0) && owner != to);  // Doesn't allow transfer to the zero address
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);
        
        // TODO: test with an approved address
        _registrarTransferHelper(owner, owner, to, notaId); // NOTE: `caller` parameter must be owner or approved
    }

    function testFailTransfer(
        address caller,
        address fakeTransferer,
        uint256 escrowed,
        uint256 instant,
        address owner, 
        address to
    ) public {
        vm.assume(caller != owner && owner != address(0) && to != address(0) && owner != to);  // Doesn't allow transfer to the zero address
        vm.assume(caller != fakeTransferer && fakeTransferer != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);
        
        // TODO: test with an approved address
        _registrarTransferHelper(fakeTransferer, owner, to, notaId); // NOTE: `caller` parameter must be owner or approved
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

        vm.warp(7 days);
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

        vm.warp(7 days);
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

        vm.warp(7 days);
        _registrarCashHelper(fakeCasher, notaId, cashAmount, fakeCasher, abi.encode(""));
    }

    function testFailCashTime(
        address payer,
        uint256 escrowed,
        address owner,
        uint256 randomTime,
        uint256 cashAmount
    ) public {
        vm.assume(randomTime < 7 days);
        uint256 notaId = _setupThenWrite(payer, escrowed, 0, owner);

        vm.warp(randomTime);
        _registrarCashHelper(owner, notaId, cashAmount, owner, abi.encode(""));
    }
}