// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import {HatsReversibleRelease} from "../src/modules/HatsReversibleRelease.sol";
import {IHats} from "hats-protocol/interfaces/IHats.sol";
import {Hats} from "hats-protocol/Hats.sol";
import {RegistrarTest} from "./Registrar.t.sol";

contract HatsReversibleReleaseTest is RegistrarTest {
    Hats public HATS;
    uint256 public adminHatId;
    uint256 public commiteeHatId;
    address public constant DAO_MEMBER = address(1);
    HatsReversibleRelease public HATS_REVERSIBLE_RELEASE;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
        HATS = new Hats("Hats", "HATS");  // Init hats contract
        HATS_REVERSIBLE_RELEASE = new HatsReversibleRelease(address(REGISTRAR), address(HATS));  // Init hook contract
        vm.label(address(HATS_REVERSIBLE_RELEASE), "ReversibleRelease");  // Label hook contract

        adminHatId = HATS.mintTopHat(address(this), "Optimism DAO", "ipfs://optimismHash"); // Create admin hat
        
        // Create hat that manages payment
        commiteeHatId = HATS.createHat(
            adminHatId,
            "Optimism Grants sub-committee", 
            100,
            address(2),
            address(3),
            true,
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png"
        );

        require(HATS.mintHat(commiteeHatId, DAO_MEMBER)); // Mint 1 hat to the DAO Member

    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) internal returns (uint256) {
        vm.assume(caller != DAO_MEMBER);
        _registrarWriteAssumptions(caller, escrowed, instant, owner); // no address(0) and not registrar or testing contract

        _registrarModuleWhitelistToggleHelper(HATS_REVERSIBLE_RELEASE, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));
        
        bytes memory initData = abi.encode(
            commiteeHatId,
            "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // document
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png" // imageURI
        );
        uint256 notaId = _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, HATS_REVERSIBLE_RELEASE, initData);
        
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

    function testCashOwner(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        _registrarCashHelper(DAO_MEMBER, notaId, escrowed, owner, "");
    }

    function testCashSender(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        _registrarCashHelper(DAO_MEMBER, notaId, escrowed, caller, "");
    }

    function testFailCashSender(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        _registrarCashHelper(caller, notaId, escrowed, caller, "");  // Sender tries to get money back
    }

    function testFailCashOwner(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        _registrarCashHelper(owner, notaId, escrowed, owner, "");  // Owner tries to take money
    }

    function testFailCashOther(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address random
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        _registrarCashHelper(DAO_MEMBER, notaId, escrowed, random, "");  // DAO Member tries to give money to a random person
    }

    function testFailHatRevokedCash(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);

        HATS.transferHat(commiteeHatId, DAO_MEMBER, address(0));  // Revoke the hat
        _registrarCashHelper(DAO_MEMBER, notaId, escrowed, owner, "");  // DAO Member no longer hat wearer
    }
}