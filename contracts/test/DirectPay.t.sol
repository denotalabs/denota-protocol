// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {Nota, WTFCFees} from "../src/libraries/DataTypes.sol";
import {DirectPayment} from "../src/modules/DirectPay.sol";
import {RegistrarTest} from "./Registrar.t.sol";

// TODO add fail tests
/**
[357688] NotaRegistrarContract::write(TestDai: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0, 0, 0xf2301Aa26da7660019Dd94A336224b0a7F723941, DirectPay: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0x0000000000000000000000009d408513222580cf45916cd32320f983dfaf2cc300000000000000000000000000000000000000000b0dc019d2fc681ec2b1f41a0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f2301aa26da7660019dd94a336224b0a7f72394100000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000002e516d625a7a44634162666e4e7152437134596d34796770314145644e4b4e34767167536355537a5232445a516376000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e516d625a7a44634162666e4e7152437134596d34796770314145644e4b4e34767167536355537a5232445a516376000000000000000000000000000000000000) 
    └─[212916] DirectPay::processWrite(0xf2301Aa26da7660019Dd94A336224b0a7F723941, 0xf2301Aa26da7660019Dd94A336224b0a7F723941, 0, TestDai: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0, 0, 0x0000000000000000000000009d408513222580cf45916cd32320f983dfaf2cc300000000000000000000000000000000000000000b0dc019d2fc681ec2b1f41a0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f2301aa26da7660019dd94a336224b0a7f72394100000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000002e516d625a7a44634162666e4e7152437134596d34796770314145644e4b4e34767167536355537a5232445a516376000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e516d625a7a44634162666e4e7152437134596d34796770314145644e4b4e34767167536355537a5232445a516376000000000000000000000000000000000000) 

Gas units: 357,688
Ethereum:
    Gas price (gwei): ~40
    Total gwei: 14,307,520
    Ether price: 1,732.50
    Write price: 24.78
Optimism:
    Gas price (gwei): ~1.6?
    Total gwei: 572,300.8
    Ether price: 1,732.50
    Write price: 0.99
Polygon:
    Gas price (gwei): ~400 (200)
    Total gwei: 143,075,200
    Matic price: 1.19
    Write Price: 0.17 (0.08)
Celo:
    Gas price (gwei): ~25
    Total gwei: 8,942,200
    Celo price: 0.63
    Write Price: 0.0056
*/
contract DirectPayTest is Test, RegistrarTest {
    DirectPayment public DIRECT_PAY;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels 
        DIRECT_PAY = new DirectPayment(
            address(REGISTRAR),
            "ipfs://"
        );

        vm.label(address(DIRECT_PAY), "DirectPay");
    }

    function _setupThenWrite(
        address caller,
        uint256 instant,
        address owner
    ) internal returns(uint256 notaId){
        vm.assume(caller != owner && owner != address(0) && caller != address(0) && instant <= TOKENS_CREATED);

        _registrarModuleWhitelistToggleHelper(DIRECT_PAY, false); // startedAs=false
        _registrarTokenWhitelistToggleHelper(address(DAI), false);

        _tokenFundAddressApproveAddress(caller, DAI, instant, address(REGISTRAR));

        notaId = _registrarWriteHelper(
            caller, 
            address(DAI), // currency
            0,  // Escrow must == 0 or reverts
            instant,
            owner, 
            DIRECT_PAY,
            abi.encode(
                "https://i.seadn.io/gcs/files/d09bf6c414378cd82ff1bc2886fcc68b.png", 
                "bafybeibj3nf4iyxt2guxihs77sylpuwu4l4yn4cfqumpc2xplxgxt4ssoa" // "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv"
            )
        );
    }

    function testWritePay(
        address caller,
        uint256 instant,
        address owner
    ) public {
        // TODO pre write module tests

        _setupThenWrite(caller, instant, owner);
        
        // TODO post write module tests
    }

    function testWriteInvoice(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        // vm.assume(faceValue != 0 && faceValue <= TOKENS_CREATED);
        // address owner = creditor;
        // vm.assume(
        //     debtor != address(0) &&
        //         creditor != address(0) &&
        //         !isContract(creditor)
        // );
        // vm.assume(debtor != creditor);

        // _writeHelper(
        //     creditor, // Who the caller should be
        //     faceValue, // Face value of invoice
        //     0, // escrowed amount
        //     0, // instant amount
        //     creditor, // The drawer
        //     debtor, // toNotify
        //     creditor // The owner
        // );

        // // INotaModule wrote correctly to it's storage
        // string memory tokenURI = REGISTRAR.tokenURI(notaId);
    }

    function testFundInvoice(
        address caller,
        uint256 faceValue,
        address recipient
    ) public {
        // vm.assume(faceValue != 0 && faceValue <= TOKENS_CREATED);
        // vm.assume(caller != recipient);
        // vm.assume(caller != address(0));
        // vm.assume(
        //     caller != address(0) &&
        //         recipient != address(0) &&
        //         !isContract(caller)
        // );

        // (uint256 notaId, DirectPay directPay) = writeHelper(
        //     caller, // Who the caller should be
        //     faceValue, // Face value of invoice
        //     0, // escrowed amount
        //     0, // instant amount
        //     caller, // The drawer
        //     recipient,
        //     caller // The owner
        // );

        // // Fund nota
        // uint256 totalWithFees = calcTotalFees(
        //     REGISTRAR,
        //     directPay,
        //     0, // escrowed amount
        //     faceValue // instant amount
        // );
        // vm.prank(recipient);
        // DAI.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
        // DAI.transfer(recipient, totalWithFees);
        // vm.assume(DAI.balanceOf(recipient) >= totalWithFees);

        // uint256 balanceBefore = DAI.balanceOf(caller);
        // vm.prank(recipient);
        // REGISTRAR.fund(
        //     notaId,
        //     0, // Escrow amount
        //     faceValue, // Instant amount
        //     abi.encode(bytes32("")) // Fund data
        // );

        // assertTrue(
        //     DAI.balanceOf(caller) - faceValue == balanceBefore,
        //     "Didnt increment balance"
        // );
    }
}
