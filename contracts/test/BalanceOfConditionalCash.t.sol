// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin/utils/Strings.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import {BalanceOfConditionalCash} from "../src/modules/BalanceOfConditionalCash.sol";
import {RegistrarTest} from "./Registrar.t.sol";
import {Noop} from "../src/modules/Noop.sol";


contract BalanceOfConditionalCashTest is RegistrarTest {
    BalanceOfConditionalCash public BALANCE_OF_CONDITIONAL_CASH;
    Noop public NOOP;
    uint256 public constant NOTA_THRESHOLD = 2;
    uint256 public constant EXPIRY = 1000;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels 
        BALANCE_OF_CONDITIONAL_CASH = new BalanceOfConditionalCash(address(REGISTRAR));  // Init hook contract
        vm.label(address(BALANCE_OF_CONDITIONAL_CASH), "BalanceOfConditionalCash");  // Label hook contract
        NOOP = new Noop(address(REGISTRAR));
        _registrarModuleWhitelistToggleHelper(NOOP, false); // startedAs=false
        vm.label(address(NOOP), "Noop");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) internal returns (uint256) {
        _registrarWriteAssumptions(caller, escrowed, instant, owner); // no address(0) and not registrar or testing contract

        _registrarModuleWhitelistToggleHelper(BALANCE_OF_CONDITIONAL_CASH, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));
        
        bytes memory initData = abi.encode(
            address(REGISTRAR), // conditionAddress
            BalanceOfConditionalCash.ConditionType.GTEQ, // conditionType
            EXPIRY, // expiry
            NOTA_THRESHOLD, // threshold
            "ipfs://QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // document
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png" // imageURI
        );
        uint256 notaId = _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, BALANCE_OF_CONDITIONAL_CASH, initData);
        
        return notaId;
    }

    function testWritePay(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        _setupThenWrite(caller, escrowed, instant, owner);
    }


    function testFund(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        vm.assume(escrowed > 1);
        _registrarWriteAssumptions(caller, escrowed, instant, owner);
        uint256 notaId = _setupThenWrite(caller, escrowed/2, instant, owner);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed/2, address(REGISTRAR));
        _registrarFundHelper(caller, notaId, escrowed/2, 0, "");
    }

    function testFailFundSender(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != owner);
        vm.assume(escrowed > 1);
        _registrarWriteAssumptions(caller, escrowed, instant, owner);
        uint256 notaId = _setupThenWrite(caller, escrowed/2, instant, owner);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed/2, caller);
        _registrarFundHelper(random, notaId, escrowed/2, 0, "");
    }

    function testFailFundExpired(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        vm.warp(EXPIRY + 1);
        _registrarFundHelper(random, notaId, escrowed, 0, "");
    }

    function testFailFundCashed(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        for (uint256 i = 0; i < NOTA_THRESHOLD; i++) {
            _registrarWriteHelper(caller, address(DAI), 0, 0, owner, NOOP, "");  // Give owner another Nota
        }

        _registrarCashHelper(owner, notaId, escrowed, owner, "");

        _registrarFundHelper(random, notaId, escrowed, 0, "");
    }

    function testCashOwner(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        for (uint256 i = 0; i < NOTA_THRESHOLD; i++) {
            _registrarWriteHelper(caller, address(DAI), 0, 0, owner, NOOP, "");  // Give owner another Nota
        }

        _registrarCashHelper(owner, notaId, escrowed, owner, "");
    }

    function testFailCashOwner(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        _registrarCashHelper(owner, notaId, escrowed, owner, "");  // Owner tries to take money without Nota balance
    }

    function testFailCashOther(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        for (uint256 i = 0; i < NOTA_THRESHOLD; i++) {
            _registrarWriteHelper(caller, address(DAI), 0, 0, owner, NOOP, "");  // Give owner another Nota
        }

        _registrarCashHelper(random, notaId, escrowed, random, "");  // Random tries to take money
    }

    function testReturnExpired(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        for (uint256 i = 0; i < NOTA_THRESHOLD; i++) {
            _registrarWriteHelper(caller, address(DAI), 0, 0, owner, NOOP, "");  // Give owner sufficient Notas
        }

        vm.warp(EXPIRY + 1);
        _registrarCashHelper(random, notaId, escrowed, caller, "");  // Random tries to take money
    }

    function testFailCashExpired(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        for (uint256 i = 0; i < NOTA_THRESHOLD; i++) {
            _registrarWriteHelper(caller, address(DAI), 0, 0, owner, NOOP, "");  // Give owner another Nota
        }

        vm.warp(EXPIRY + 1 days);
        _registrarCashHelper(random, notaId, escrowed, owner, "");  // Random tries to take money
    }

    function testFailBalanceDecrementCash(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        for (uint256 i = 0; i < NOTA_THRESHOLD; i++) {
            _registrarTransferHelper(owner, owner, random, _registrarWriteHelper(caller, address(DAI), 0, 0, owner, NOOP, ""));
        }
        _registrarCashHelper(owner, notaId, escrowed, owner, "");  // Owner had Nota, but it was transferred
    }

    function testFailUncashedTransfer(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != owner && random != address(0) && escrowed != 0);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);
    
        _registrarTransferHelper(owner, owner, random, notaId);
    }

    function testCashOwnerTransfer(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        vm.assume(random != address(0) && random != owner);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        for (uint256 i = 0; i < NOTA_THRESHOLD; i++) {
            _registrarWriteHelper(caller, address(DAI), 0, 0, owner, NOOP, "");  // Give owner another Nota
        }

        _registrarCashHelper(owner, notaId, escrowed, owner, "");

        _registrarTransferHelper(owner, owner, random, notaId);
    }
}