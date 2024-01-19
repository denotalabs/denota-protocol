// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import {DirectSend} from "../src/modules/DirectSend.sol";
import {RegistrarTest} from "./Registrar.t.sol";


contract DirectSendTest is RegistrarTest {
    DirectSend public DIRECT_SEND;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels 
        DIRECT_SEND = new DirectSend(address(REGISTRAR));

        vm.label(address(DIRECT_SEND), "DirectSend");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) internal returns(uint256 notaId){
        vm.assume(caller != owner && owner != address(0) && caller != address(0) && instant <= TOKENS_CREATED);

        _registrarModuleWhitelistToggleHelper(DIRECT_SEND, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, instant, address(REGISTRAR));

        notaId = _registrarWriteHelper(
            caller, 
            address(DAI), // currency
            escrowed,  // Escrow == 0 or reverts
            instant,
            owner, 
            DIRECT_SEND,
            abi.encode(
                "https://app.denota.xyz", // "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv"
                "https://i.seadn.io/gcs/files/d09bf6c414378cd82ff1bc2886fcc68b.png"
            )
        );
    }

    function testWritePay(
        address caller,
        uint256 instant,
        address owner
    ) public {
        // TODO pre write module tests

        uint256 notaId = _setupThenWrite(caller, 0, instant, owner);
        
        // TODO post write module tests
        console.log(REGISTRAR.tokenURI(notaId));
    }

    function testFailWritePay(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        vm.assume(escrowed > 0);

        _setupThenWrite(caller, escrowed, instant, owner);
        
        // TODO post write module tests
    }

    function testTransferPay(
        address caller,
        uint256 instant,
        address owner,
        address to
    ) public {
        vm.assume(owner != address(0) && caller != address(0) && to != address(0));
        vm.assume(owner != to);
        uint256 notaId = _setupThenWrite(caller, 0, instant, owner);

        _registrarTransferHelper(owner, owner, to, notaId);
    }

    function testFailFund(
        address caller,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, 0, instant, owner);

        _registrarFundHelper(caller, notaId, 0, 0, "");
    }

    function testFailCash(
        address caller,
        uint256 instant,
        uint256 amount,
        address owner
    ) public {

        uint256 notaId = _setupThenWrite(caller, 0, instant, owner);

        _registrarCashHelper(caller, notaId, amount, owner, "");        
    }
}
