// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {MilestonesPayment} from "../src/modules/Milestones.sol";
import {RegistrarTest} from "./Registrar.t.sol";

// TODO add fail tests
/// TODO Failing occasionally on invoice functions
contract MilestonesTest is Test, RegistrarTest {
    MilestonesPayment public MILESTONES;

    function setUp() public override {
        super.setUp();
        MILESTONES = new MilestonesPayment(
            address(REGISTRAR),
            "ipfs://yourmemos.com/"
        );
        vm.label(address(MILESTONES), "Milestones");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        bytes memory moduleBytes
    ) internal returns(uint256 notaId){
        // TODO pre write module tests

        _registrarWriteAssumptions(caller, escrowed, instant,owner); // TODO move to registrar test?
        _registrarModuleWhitelistToggleHelper(MILESTONES, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, escrowed + instant, address(REGISTRAR));
        notaId = _registrarWriteHelper(
            caller, 
            address(DAI), // currency
            escrowed, 
            instant,
            owner, 
            MILESTONES, // module
            moduleBytes
        );
        // TODO post write module tests
    }

    function testWrite(
        address caller,
        uint256 instant,
        address owner,
        uint256 firstMilestone,
        uint256 secondMilestone
    ) public {
        // // TODO need to test edge cases for arrays
        uint256[] memory milestoneAmounts = new uint256[](2);
        milestoneAmounts[0] = firstMilestone;
        milestoneAmounts[1] = secondMilestone;
        bytes memory moduleBytes = abi.encode(
            bytes32(keccak256("this is a hash")),
            milestoneAmounts
        );

        _setupThenWrite(caller, firstMilestone, instant, owner, moduleBytes);
    }

    function testTransfer() public {}

    function testFund() public {}

    function testCash(
        address creditor,
        uint256 secondMilestone,
        uint256 firstMilestone,
        address debtor
    ) public {
        // vm.assume(
        //     writeConditions(
        //         creditor, // caller
        //         firstMilestone,
        //         secondMilestone,
        //         debtor,
        //         creditor
        //     )
        // );

        // // First milestone must be escrowed (or instant and second escrowed)
        // (uint256 notaId, Milestones milestones) = writeHelper(
        //     debtor, // caller
        //     secondMilestone, // escrowed amount
        //     firstMilestone, // instant amount
        //     creditor, // toNotify
        //     creditor // The owner
        // ); // Instant pay the first, escrow second

        // fundHelper(notaId, debtor, 0, 0, milestones); // release second

        // bytes memory cashData = abi.encode(1, address(0)); // cash second milestone
        // vm.prank(creditor);
        // REGISTRAR.cash(notaId, secondMilestone, creditor, cashData);
    }
}