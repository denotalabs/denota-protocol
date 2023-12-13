// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota, WTFCFees} from "../src/libraries/DataTypes.sol";
import {ReversibleRelease} from "../src/modules/ReversibleRelease.sol";
import {RegistrarTest} from "./Registrar.t.sol";

// TODO add fail tests
contract ReversibleReleaseTest is Test, RegistrarTest {
    ReversibleRelease public REVERSIBLE_RELEASE;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
        REVERSIBLE_RELEASE = new ReversibleRelease(address(REGISTRAR));
        vm.label(address(REVERSIBLE_RELEASE), "ReversibleRelease");
    }

    function writeAssumptions(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public view {
        vm.assume(debtor != creditor);
        vm.assume(faceValue != 0 && faceValue <= TOKENS_CREATED);
        vm.assume(
            debtor != address(0) &&
                creditor != address(0) &&
                !isContract(creditor)
        );
    }

    function _writeHelper(
        address caller,
        uint256 amount, // faceValue
        uint256 escrowed,
        uint256 instant,
        address toNotify, // toNotify
        address owner,
        address inspector
    ) internal returns (uint256) {
        // TODO module specific state testing

        bytes memory initData = abi.encode(
            toNotify, // toNotify
            inspector, // inspector
            address(0), // dappOperator
            amount, // faceValue
            "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // docHash
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png" // imageURI
        );
        uint256 notaId = _registrarWriteHelper(caller, address(DAI), escrowed, instant, owner, REVERSIBLE_RELEASE, initData);
        
        // TODO module specific state testing
        string memory tokenURI = REGISTRAR.tokenURI(notaId);

        return notaId;
    }

    function testWritePay(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner,
        uint256 faceValue,
        address toNotify,
        address inspector
    ) public {
         uint256 notaId = _writeHelper(caller, faceValue, escrowed,instant,toNotify, owner,inspector);
    }

    function testWriteInvoice(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
    }

    function testTransferPayment() public {}

    function testTransferInvoice() public {}

//     function fundHelper(
//         uint256 notaId,
//         ReversibleRelease reversibleRelease,
//         uint256 fundAmount,
//         address debtor,
//         address /*creditor*/
//     ) public {
//         uint256 totalWithFees = calcTotalFees(
//             REGISTRAR,
//             reversibleRelease,
//             fundAmount, // escrowed amount
//             0 // instant amount
//         );
//         vm.prank(debtor);
//         DAI.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand

//         DAI.transfer(debtor, totalWithFees);
//         vm.assume(DAI.balanceOf(debtor) >= totalWithFees);

//         uint256 debtorBalanceBefore = DAI.balanceOf(debtor);

//         vm.prank(debtor);
//         REGISTRAR.fund(
//             notaId,
//             fundAmount, // Escrow amount
//             0, // Instant amount
//             abi.encode(address(0)) // Fund data
//         );

//         assertTrue(
//             debtorBalanceBefore - fundAmount == DAI.balanceOf(debtor),
//             "Didnt decrement balance"
//         );
//     }

//     function testFundInvoice(
//         address debtor,
//         uint256 faceValue,
//         address creditor
//     ) public {
//         writeAssumptions(debtor, faceValue, creditor);

//         (uint256 notaId, ReversibleRelease reversibleRelease) = writeHelper(
//             creditor, // Who the caller should be
//             faceValue, // Face value of invoice
//             0, // escrowed amount
//             0, // instant amount
//             debtor, // toNotify
//             creditor, // The owner
//             address(this)
//         );

//         // Fund nota
//         fundHelper(notaId, reversibleRelease, faceValue, debtor, creditor);
//     }

//     function testCashInvoice(
//         address debtor,
//         uint256 faceValue,
//         address creditor
//     ) public {
//         writeAssumptions(debtor, faceValue, creditor);

//         (uint256 notaId, ReversibleRelease reversibleRelease) = writeHelper(
//             creditor, // Who the caller should be
//             faceValue, // Face value of invoice
//             0, // escrowed amount
//             0, // instant amount
//             debtor, // toNotify
//             creditor, // The owner
//             address(this)
//         );

//         // Fund nota
//         fundHelper(notaId, reversibleRelease, faceValue, debtor, creditor);

//         uint256 balanceBefore = DAI.balanceOf(creditor);
//         vm.prank(address(this));
//         REGISTRAR.cash(
//             notaId,
//             faceValue, // amount to cash
//             creditor, // to
//             bytes(abi.encode(address(0))) // dappOperator
//         );

//         assertTrue(balanceBefore + faceValue == DAI.balanceOf(creditor));
//     }

//     function testCashPayment(
//         address debtor,
//         uint256 faceValue,
//         address creditor
//     ) public {
//         writeAssumptions(debtor, faceValue, creditor);
//         (
//             uint256 notaId /*ReversibleRelease reversibleRelease*/,

//         ) = writeHelper(
//                 debtor, // Caller
//                 faceValue, // Face value
//                 faceValue, // escrowed
//                 0, // instant
//                 creditor, // toNotify
//                 creditor, // Owner
//                 address(this)
//             );

//         uint256 balanceBefore = DAI.balanceOf(creditor);
//         vm.prank(address(this));
//         REGISTRAR.cash(
//             notaId, //
//             faceValue, // amount to cash
//             creditor, // to
//             bytes(abi.encode(""))
//         );

//         assertTrue(DAI.balanceOf(creditor) - balanceBefore == faceValue);
//     }

//     function testFundTransferInvoice(
//         address debtor,
//         uint256 faceValue,
//         address creditor
//     ) public {
//         writeAssumptions(debtor, faceValue, creditor);

//         (uint256 notaId, ReversibleRelease reversibleRelease) = writeHelper(
//             creditor, // Who the caller should be
//             faceValue, // Face value of invoice
//             0, // escrowed amount
//             0, // instant amount
//             debtor, // toNotify
//             creditor, // The owner
//             address(this)
//         );

//         // Fund nota
//         fundHelper(notaId, reversibleRelease, faceValue, debtor, creditor);

//         vm.prank(creditor);
//         REGISTRAR.safeTransferFrom(
//             creditor,
//             address(1),
//             notaId,
//             abi.encode(bytes32("")) // transfer data
//         );
//     }

//     function testReversePayment(
//         address debtor,
//         uint256 faceValue,
//         address creditor
//     ) public {
//         writeAssumptions(debtor, faceValue, creditor);

//         (
//             uint256 notaId /*ReversibleRelease reversibleRelease*/,

//         ) = writeHelper(
//                 debtor, // Who the caller should be
//                 faceValue, // Face value of invoice
//                 faceValue, // escrowed amount
//                 0, // instant amount
//                 creditor, // toNotify
//                 creditor, // The owner
//                 address(this)
//             );

//         uint256 balanceBefore = DAI.balanceOf(creditor);
//         vm.prank(address(this));
//         REGISTRAR.cash(
//             notaId, //
//             faceValue, // amount
//             debtor, // to
//             bytes(abi.encode(""))
//         );

//         assertTrue(
//             balanceBefore + faceValue == DAI.balanceOf(debtor),
//             "Incorrect cash out"
//         );
//     }

//     function testReverseInvoice(
//         address debtor,
//         uint256 faceValue,
//         address creditor
//     ) public {
//         writeAssumptions(debtor, faceValue, creditor);

//         uint256 notaId = _writeHelper(
//             creditor, // Who the caller should be
//             faceValue, // Face value of invoice
//             0, // escrowed amount
//             0, // instant amount
//             debtor, // toNotify
//             creditor, // The owner
//             address(this)
//         );

//         // Fund nota
//         fundHelper(notaId, faceValue, debtor, creditor);
//     }
}