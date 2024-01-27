// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import {ReversibleReleasePayment} from "../src/modules/ReversibleRelease.sol";
import {RegistrarTest} from "./Registrar.t.sol";

// TODO add fail tests
contract ReversibleReleaseTest is RegistrarTest {
    ReversibleReleasePayment public REVERSIBLE_RELEASE;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
        REVERSIBLE_RELEASE = new ReversibleReleasePayment(address(REGISTRAR));
        vm.label(address(REVERSIBLE_RELEASE), "ReversibleRelease");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        bytes memory initData
    ) internal returns (uint256) {
        // TODO module specific state testing
        _registrarWriteAssumptions(caller, escrowed, instant, owner); // no address(0) and not registrar or testing contract

        _registrarModuleWhitelistToggleHelper(REVERSIBLE_RELEASE, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));
        uint256 notaId = _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, REVERSIBLE_RELEASE, initData);
        
        // TODO module specific state testing

        return notaId;
    }

    function testWritePay(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address inspector
    ) public {
        vm.assume(inspector != address(0));
        bytes memory initData = abi.encode(
            inspector,
            "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // docHash
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png" // imageURI
        );

        _setupThenWrite(caller, escrowed, instant, owner, initData);
    }

    function testTransferPayment() public {

    }
}