// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {DirectPay} from "../src/modules/DirectPay.sol";

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
contract DirectPayTest is Test {
    NotaRegistrar public REGISTRAR;
    TestERC20 public dai;
    TestERC20 public usdc;
    uint256 public immutable tokensCreated = 1_000_000_000_000e18;

    function isContract(address _addr) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setUp() public {
        // sets up the registrar and ERC20s
        REGISTRAR = new NotaRegistrar(); // ContractTest is the owner
        dai = new TestERC20(tokensCreated, "DAI", "DAI"); // Sends ContractTest the dai
        usdc = new TestERC20(0, "USDC", "USDC");
        // REGISTRAR.whitelistToken(address(dai), true);
        // REGISTRAR.whitelistToken(address(usdc), true);

        vm.label(msg.sender, "Alice");
        vm.label(address(this), "TestContract");
        vm.label(address(dai), "TestDai");
        vm.label(address(usdc), "TestUSDC");
        vm.label(address(REGISTRAR), "NotaRegistrarContract");
    }

    // function whitelist(address module) public {
    //     // Whitelists tokens, rules, modules
    //     // REGISTRAR.whitelistRule(rule, true);
    //     REGISTRAR.whitelistModule(module, false, true, "Direct Pay"); // Whitelist bytecode
    // }

    /*//////////////////////////////////////////////////////////////
                            WHITELIST TESTS
    //////////////////////////////////////////////////////////////*/
    // function testWhitelistToken() public {
    //     address daiAddress = address(dai);
    //     vm.prank(address(this));

    //     // Whitelist tokens
    //     assertFalse(
    //         REGISTRAR.tokenWhitelisted(daiAddress),
    //         "Unauthorized whitelist"
    //     );
    //     REGISTRAR.whitelistToken(daiAddress, true, "DAI");
    //     assertTrue(
    //         REGISTRAR.tokenWhitelisted(daiAddress),
    //         "Whitelisting failed"
    //     );
    //     REGISTRAR.whitelistToken(daiAddress, false, "DAI");
    //     assertFalse(
    //         REGISTRAR.tokenWhitelisted(daiAddress),
    //         "Un-whitelisting failed"
    //     );

    //     // Whitelist rules
    //     // DirectPayRules directPayRules = new DirectPayRules();
    //     // address directPayRulesAddress = address(directPayRules);
    //     // assertFalse(
    //     //     REGISTRAR.ruleWhitelisted(directPayRulesAddress),
    //     //     "Unauthorized whitelist"
    //     // );
    //     // REGISTRAR.whitelistRule(directPayRulesAddress, true); // whitelist bytecode, not address
    //     // assertTrue(
    //     //     REGISTRAR.ruleWhitelisted(directPayRulesAddress),
    //     //     "Whitelisting failed"
    //     // );
    //     // REGISTRAR.whitelistRule(directPayRulesAddress, false);
    //     // assertFalse(
    //     //     REGISTRAR.ruleWhitelisted(directPayRulesAddress),
    //     //     "Un-whitelisting failed"
    //     // );
    //     // REGISTRAR.whitelistRule(directPayRulesAddress, true); // whitelist bytecode, not address

    //     // Whitelist module
    //     DirectPay directPay = new DirectPay(
    //         address(REGISTRAR),
    //         DataTypes.WTFCFees(0, 0, 0, 0),
    //         "ipfs://"
    //     );
    //     address directPayAddress = address(directPay);
    //     (bool addressWhitelisted, bool bytecodeWhitelisted) = REGISTRAR
    //         .moduleWhitelisted(directPayAddress);
    //     assertFalse(
    //         addressWhitelisted || bytecodeWhitelisted,
    //         "Unauthorized whitelist"
    //     );
    //     REGISTRAR.whitelistModule(directPayAddress, true, false, "Direct Pay"); // whitelist bytecode, not address
    //     (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(
    //         directPayAddress
    //     );
    //     assertTrue(
    //         addressWhitelisted || bytecodeWhitelisted,
    //         "Whitelisting failed"
    //     );
    //     REGISTRAR.whitelistModule(directPayAddress, false, false, "Direct Pay");
    //     (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(
    //         directPayAddress
    //     );
    //     assertFalse(
    //         addressWhitelisted || bytecodeWhitelisted,
    //         "Un-whitelisting failed"
    //     );
    // }

    // function testFailWhitelist(address caller) public {
    //     vm.assume(caller == address(0));  // Deployer can whitelist, test others accounts
    //     Marketplace market = new Marketplace(REGISTRAR);
    //     vm.prank(caller);
    //     REGISTRAR.whitelistModule(market, true);
    //     assertFalse(REGISTRAR.moduleWhitelisted(address(this), market), "Unauthorized whitelist");
    // }

    function setUpDirectPay() public returns (DirectPay) {
        // Deploy and whitelist module
        DirectPay directPay = new DirectPay(
            address(REGISTRAR),
            DataTypes.WTFCFees(0, 0, 0, 0),
            "ipfs://"
        );
        // REGISTRAR.whitelistModule(
        //     address(directPay),
        //     true,
        //     false,
        //     "Direct Pay"
        // );
        vm.label(address(directPay), "DirectPay");
        return directPay;
    }

    /*//////////////////////////////////////////////////////////////
                            MODULE TESTS
    //////////////////////////////////////////////////////////////*/
    function calcFee(
        uint256 fee,
        uint256 amount
    ) public pure returns (uint256) {
        return (amount * fee) / 10_000;
    }

    function notaWriteCondition(
        address caller,
        uint256 amount,
        uint256 escrowed,
        address drawer,
        address recipient,
        address owner
    ) public view returns (bool) {
        return
            (amount != 0) && // nota must have a face value
            (drawer != recipient) && // Drawer and recipient aren't the same
            (owner == drawer || owner == recipient) && // Either drawer or recipient must be owner
            (caller == drawer || caller == recipient) && // Delegated pay/requesting not allowed
            (escrowed == 0 || escrowed == amount) && // Either send unfunded or fully funded nota
            (recipient != address(0) &&
                owner != address(0) &&
                drawer != address(0)) &&
            // Testing conditions
            (amount <= tokensCreated) && // Can't use more token than created
            (caller != address(0)) && // Don't vm.prank from address(0)
            !isContract(owner); // Don't send notas to non-ERC721Reciever contracts
    }

    function registrarWriteBefore(address caller, address recipient) public {
        assertTrue(
            REGISTRAR.balanceOf(caller) == 0,
            "Caller already had a nota"
        );
        assertTrue(
            REGISTRAR.balanceOf(recipient) == 0,
            "Recipient already had a nota"
        );
        assertTrue(REGISTRAR.totalSupply() == 0, "nota supply non-zero");
    }

    function registrarWriteAfter(
        uint256 notaId,
        uint256 /*amount*/,
        uint256 escrowed,
        address owner,
        address drawer,
        address recipient,
        address module
    ) public {
        assertTrue(
            REGISTRAR.totalSupply() == 1,
            "nota supply didn't increment"
        );
        assertTrue(
            REGISTRAR.ownerOf(notaId) == owner,
            "`owner` isn't owner of nota"
        );
        assertTrue(
            REGISTRAR.balanceOf(owner) == 1,
            "Owner balance didn't increment"
        );

        // NotaRegistrar wrote correctly to its storage
        // assertTrue(REGISTRAR.notaDrawer(notaId) == drawer, "Incorrect drawer");
        // assertTrue(
        //     REGISTRAR.notaRecipient(notaId) == recipient,
        //     "Incorrect recipient"
        // );
        assertTrue(
            REGISTRAR.notaCurrency(notaId) == address(dai),
            "Incorrect token"
        );
        // assertTrue(REGISTRAR.notaAmount(notaId) == amount, "Incorrect amount");
        assertTrue(
            REGISTRAR.notaEscrowed(notaId) == escrowed,
            "Incorrect escrow"
        );
        assertTrue(
            address(REGISTRAR.notaModule(notaId)) == module,
            "Incorrect module"
        );
    }

    function testWritePay(
        address debtor,
        uint256 directAmount,
        address creditor
    ) public {
        vm.assume(directAmount != 0 && directAmount <= tokensCreated);
        vm.assume(
            debtor != address(0) &&
                creditor != address(0) &&
                !isContract(creditor)
        );
        vm.assume(debtor != creditor);

        DirectPay directPay = setUpDirectPay();
        uint256 totalWithFees;
        {
            DataTypes.WTFCFees memory fees = directPay.getFees(address(0));
            uint256 moduleFee = calcFee(fees.writeBPS, directAmount);
            console.log("ModuleFee: ", moduleFee);
            totalWithFees = directAmount + moduleFee;
            console.log(directAmount, "-->", totalWithFees);
        }

        // REGISTRAR.whitelistToken(address(dai), true, "DAI");
        vm.prank(debtor);
        dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
        dai.transfer(debtor, totalWithFees);
        vm.assume(dai.balanceOf(debtor) >= totalWithFees);

        registrarWriteBefore(debtor, creditor);
        bytes memory initData = abi.encode(
            creditor, // ToNotify
            directAmount,
            // block.timestamp,
            100,
            address(this), // dappOperator
            "https://i.seadn.io/gcs/files/d09bf6c414378cd82ff1bc2886fcc68b.png", 
            "bafybeibj3nf4iyxt2guxihs77sylpuwu4l4yn4cfqumpc2xplxgxt4ssoa"
            // "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv",
            // "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv"
        );
        vm.prank(debtor);
        uint256 notaId = REGISTRAR.write(
            address(dai),
            0,
            directAmount,
            creditor, // Owner
            address(directPay),
            initData
        );
        registrarWriteAfter(
            notaId,
            directAmount,
            0,
            creditor, // Owner
            debtor, // Drawer
            creditor, // Recipient
            address(directPay)
        );

        // INotaModule wrote correctly to it's storage
        string memory tokenURI = REGISTRAR.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    function testWriteInvoice(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        vm.assume(faceValue != 0 && faceValue <= tokensCreated);
        address owner = creditor;
        vm.assume(
            debtor != address(0) &&
                creditor != address(0) &&
                !isContract(creditor)
        );
        vm.assume(debtor != creditor);

        (uint256 notaId, DirectPay directPay) = writeHelper(
            creditor, // Who the caller should be
            faceValue, // Face value of invoice
            0, // escrowed amount
            0, // instant amount
            creditor, // The drawer
            debtor, // toNotify
            creditor // The owner
        );

        // INotaModule wrote correctly to it's storage
        string memory tokenURI = REGISTRAR.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    function calcTotalFees(
        NotaRegistrar registrar,
        DirectPay directPay,
        uint256 escrowed,
        uint256 directAmount
    ) public view returns (uint256) {
        DataTypes.WTFCFees memory fees = directPay.getFees(address(0));
        uint256 moduleFee = calcFee(fees.writeBPS, directAmount + escrowed);
        console.log("ModuleFee: ", moduleFee);
        uint256 totalWithFees = escrowed + directAmount + moduleFee;
        console.log(directAmount, "-->", totalWithFees);
        return totalWithFees;
    }

    function writeHelper(
        address caller,
        uint256 amount,
        uint256 escrowed,
        uint256 directAmount,
        address drawer,
        address recipient,
        address owner
    ) public returns (uint256, DirectPay) {
        DirectPay directPay = setUpDirectPay();

        uint256 totalWithFees = calcTotalFees(
            REGISTRAR,
            directPay,
            escrowed,
            directAmount
        );
        // REGISTRAR.whitelistToken(address(dai), true, "DAI");
        vm.prank(caller);
        dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
        dai.transfer(caller, totalWithFees);
        vm.assume(dai.balanceOf(caller) >= totalWithFees);

        registrarWriteBefore(caller, recipient);

        /**
        address toNotify,
        uint256 amount, // Face value (for invoices)
        // uint256 timestamp,
        uint256 dueDate,
        address dappOperator,
        string memory imageURI,
        string memory memoHash
         */

        bytes memory initData = abi.encode(
            recipient,
            amount,
            // block.timestamp,
            100, // due data
            caller,
            "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv",
            "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv"
        );

        console.log(amount, directAmount, totalWithFees);
        vm.prank(caller);
        uint256 notaId = REGISTRAR.write(
            address(dai),
            escrowed,
            directAmount,
            owner,
            address(directPay),
            initData
        ); // Sets caller as owner
        registrarWriteAfter(
            notaId,
            amount,
            0,
            owner,
            drawer,
            recipient,
            address(directPay)
        );
        return (notaId, directPay);
    }

    function testFundInvoice(
        address caller,
        uint256 faceValue,
        address recipient
    ) public {
        vm.assume(faceValue != 0 && faceValue <= tokensCreated);
        vm.assume(caller != recipient);
        vm.assume(caller != address(0));
        vm.assume(
            caller != address(0) &&
                recipient != address(0) &&
                !isContract(caller)
        );

        (uint256 notaId, DirectPay directPay) = writeHelper(
            caller, // Who the caller should be
            faceValue, // Face value of invoice
            0, // escrowed amount
            0, // instant amount
            caller, // The drawer
            recipient,
            caller // The owner
        );

        // Fund nota
        uint256 totalWithFees = calcTotalFees(
            REGISTRAR,
            directPay,
            0, // escrowed amount
            faceValue // instant amount
        );
        vm.prank(recipient);
        dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
        dai.transfer(recipient, totalWithFees);
        vm.assume(dai.balanceOf(recipient) >= totalWithFees);

        uint256 balanceBefore = dai.balanceOf(caller);
        vm.prank(recipient);
        REGISTRAR.fund(
            notaId,
            0, // Escrow amount
            faceValue, // Instant amount
            abi.encode(bytes32("")) // Fund data
        );

        assertTrue(
            dai.balanceOf(caller) - faceValue == balanceBefore,
            "Didnt increment balance"
        );
    }

    function testFundTransferInvoice(
        address caller,
        uint256 faceValue,
        address recipient
    ) public {
        vm.assume(faceValue != 0 && faceValue <= tokensCreated);
        vm.assume(caller != recipient);
        vm.assume(caller != address(0));
        vm.assume(
            caller != address(0) &&
                recipient != address(0) &&
                !isContract(caller)
        );
        (uint256 notaId, DirectPay directPay) = writeHelper(
            caller, // Who the caller should be
            faceValue, // Face value of invoice
            0, // escrowed amount
            0, // instant amount
            caller, // The drawer
            recipient,
            caller // The owner
        );
        // Fund nota
        uint256 totalWithFees = calcTotalFees(
            REGISTRAR,
            directPay,
            0, // escrowed amount
            faceValue // instant amount
        );
        vm.prank(recipient);
        dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
        dai.transfer(recipient, totalWithFees);
        vm.assume(dai.balanceOf(recipient) >= totalWithFees);
        uint256 balanceBefore = dai.balanceOf(caller);
        vm.prank(recipient);
        REGISTRAR.fund(
            notaId,
            0, // Escrow amount
            faceValue, // Instant amount
            abi.encode(bytes32("")) // Fund data
        );
        assertTrue(dai.balanceOf(caller) - faceValue == balanceBefore);

        vm.prank(caller);
        // REGISTRAR.safeTransferFrom(
        //     caller,
        //     address(1),
        //     notaId,
        //     abi.encode(bytes32("")) // transfer data
        // );
        REGISTRAR.transferFrom(caller, address(1), notaId);
    }
}
