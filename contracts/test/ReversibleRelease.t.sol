// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {ReversibleRelease} from "../src/modules/ReversibleRelease.sol";

// TODO add fail tests
contract ReversibleReleaseTest is Test {
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
    //     REGISTRAR.whitelistModule(module, false, true, "Reversible Release"); // Whitelist bytecode
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
    //     // Whitelist module
    //     ReversibleRelease reversibleRelease = new ReversibleRelease(
    //         address(REGISTRAR),
    //         DataTypes.WTFCFees(0, 0, 0, 0),
    //         "ipfs://"
    //     );
    //     address reversibleReleaseAddress = address(reversibleRelease);
    //     (bool addressWhitelisted, bool bytecodeWhitelisted) = REGISTRAR
    //         .moduleWhitelisted(reversibleReleaseAddress);
    //     assertFalse(
    //         addressWhitelisted || bytecodeWhitelisted,
    //         "Unauthorized whitelist"
    //     );
    //     REGISTRAR.whitelistModule(
    //         reversibleReleaseAddress,
    //         true,
    //         false,
    //         "Reversible Release"
    //     ); // whitelist bytecode, not address
    //     (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(
    //         reversibleReleaseAddress
    //     );
    //     assertTrue(
    //         addressWhitelisted || bytecodeWhitelisted,
    //         "Whitelisting failed"
    //     );
    //     REGISTRAR.whitelistModule(
    //         reversibleReleaseAddress,
    //         false,
    //         false,
    //         "Reversible Release"
    //     );
    //     (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(
    //         reversibleReleaseAddress
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

    function setUpReversibleRelease() public returns (ReversibleRelease) {
        // Deploy and whitelist module
        ReversibleRelease reversibleRelease = new ReversibleRelease(
            address(REGISTRAR),
            DataTypes.WTFCFees(0, 0, 0, 0),
            "https://"
        );
        // REGISTRAR.whitelistModule(
        //     address(reversibleRelease),
        //     true,
        //     false,
        //     "Reversible Release"
        // );
        vm.label(address(reversibleRelease), "ReversibleRelease");
        return reversibleRelease;
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

    // function notaWriteCondition(
    //     address caller,
    //     uint256 amount,
    //     uint256 escrowed,
    //     address drawer,
    //     address recipient,
    //     address owner
    // ) public view returns (bool) {
    //     return
    //         (amount != 0) && // nota must have a face value
    //         (drawer != recipient) && // Drawer and recipient aren't the same
    //         (owner == drawer || owner == recipient) && // Either drawer or recipient must be owner
    //         (caller == drawer || caller == recipient) && // Delegated pay/requesting not allowed
    //         (escrowed == 0 || escrowed == amount) && // Either send unfunded or fully funded nota
    //         (recipient != address(0) &&
    //             owner != address(0) &&
    //             drawer != address(0)) &&
    //         // Testing conditions
    //         (amount <= tokensCreated) && // Can't use more token than created
    //         (caller != address(0)) && // Don't vm.prank from address(0)
    //         !isContract(owner); // Don't send notas to non-ERC721Reciever contracts
    // }

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
        uint256 escrowed,
        address owner,
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
        uint256 escrowed,
        address creditor
    ) public {
        writeAssumptions(debtor, escrowed, creditor);

        ReversibleRelease reversibleRelease = setUpReversibleRelease();
        uint256 totalWithFees = calcTotalFees(
            REGISTRAR,
            reversibleRelease,
            escrowed,
            0
        );

        // REGISTRAR.whitelistToken(address(dai), true, "DAI");
        vm.prank(debtor);
        dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
        dai.transfer(debtor, totalWithFees);
        vm.assume(dai.balanceOf(debtor) >= totalWithFees);

        registrarWriteBefore(debtor, creditor);
        bytes memory initData = abi.encode(
            creditor, // toNotify
            address(this), // inspector
            address(0), // dappOperator
            escrowed, // faceValue
            "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // docHash
            "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv" // imageURI
        );
        vm.prank(debtor);
        uint256 notaId = REGISTRAR.write(
            address(dai),
            escrowed,
            0, // instant
            creditor, // Owner
            address(reversibleRelease),
            initData
        );
        registrarWriteAfter(
            notaId,
            escrowed, // Escrowed
            creditor, // Owner
            address(reversibleRelease)
        );

        // INotaModule wrote correctly to it's storage
        string memory tokenURI = REGISTRAR.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    function calcTotalFees(
        NotaRegistrar registrar,
        ReversibleRelease reversibleRelease,
        uint256 escrowed,
        uint256 instant
    ) public view returns (uint256) {
        DataTypes.WTFCFees memory fees = reversibleRelease.getFees(address(0));
        uint256 moduleFee = calcFee(fees.writeBPS, instant + escrowed);
        console.log("ModuleFee: ", moduleFee);
        uint256 totalWithFees = escrowed + moduleFee;
        console.log(escrowed, "-->", totalWithFees);
        return totalWithFees;
    }

    function writeHelper(
        address caller,
        uint256 amount, // faceValue
        uint256 escrowed,
        uint256 instant,
        address toNotify, // toNotify
        address owner,
        address inspector
    ) public returns (uint256, ReversibleRelease) {
        ReversibleRelease reversibleRelease = setUpReversibleRelease();

        uint256 totalWithFees = calcTotalFees(
            REGISTRAR,
            reversibleRelease,
            escrowed,
            instant
        );
        // REGISTRAR.whitelistToken(address(dai), true, "DAI");
        vm.prank(caller);
        dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
        dai.transfer(caller, totalWithFees);
        vm.assume(dai.balanceOf(caller) >= totalWithFees);

        registrarWriteBefore(caller, toNotify);

        bytes memory initData = abi.encode(
            toNotify, // toNotify
            inspector, // inspector
            address(0), // dappOperator
            amount, // faceValue
            "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv", // docHash
            "cerealclub.mypinata.cloud/ipfs/QmQ9sr73woB8cVjq5ppUxzNoRwWDVmK7Vu65zc3R7Dbv1Z/2806.png" // imageURI
        );

        console.log(amount, instant, totalWithFees);
        vm.prank(caller);
        uint256 notaId = REGISTRAR.write(
            address(dai),
            escrowed,
            instant,
            owner,
            address(reversibleRelease),
            initData
        ); // Sets caller as owner
        registrarWriteAfter(
            notaId,
            escrowed,
            owner,
            address(reversibleRelease)
        );
        // INotaModule wrote correctly to it's storage
        string memory tokenURI = REGISTRAR.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
        return (notaId, reversibleRelease);
    }

    function fundHelper(
        uint256 notaId,
        ReversibleRelease reversibleRelease,
        uint256 fundAmount,
        address debtor,
        address creditor
    ) public {
        uint256 totalWithFees = calcTotalFees(
            REGISTRAR,
            reversibleRelease,
            fundAmount, // escrowed amount
            0 // instant amount
        );
        vm.prank(debtor);
        dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand

        dai.transfer(debtor, totalWithFees);
        vm.assume(dai.balanceOf(debtor) >= totalWithFees);

        uint256 debtorBalanceBefore = dai.balanceOf(debtor);

        vm.prank(debtor);
        REGISTRAR.fund(
            notaId,
            fundAmount, // Escrow amount
            0, // Instant amount
            abi.encode(address(0)) // Fund data
        );

        assertTrue(
            debtorBalanceBefore - fundAmount == dai.balanceOf(debtor),
            "Didnt decrement balance"
        );
    }

    function writeAssumptions(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public view {
        vm.assume(debtor != creditor);
        vm.assume(faceValue != 0 && faceValue <= tokensCreated);
        vm.assume(
            debtor != address(0) &&
                creditor != address(0) &&
                !isContract(creditor)
        );
    }

    function testWriteInvoice(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        writeAssumptions(debtor, faceValue, creditor);
        writeHelper(
            creditor, // Who the caller should be
            faceValue, // Face value of invoice
            0, // escrowed amount
            0, // instant amount
            debtor, // toNotify
            creditor, // The owner
            address(this)
        );
    }

    function testFundInvoice(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        writeAssumptions(debtor, faceValue, creditor);

        (uint256 notaId, ReversibleRelease reversibleRelease) = writeHelper(
            creditor, // Who the caller should be
            faceValue, // Face value of invoice
            0, // escrowed amount
            0, // instant amount
            debtor, // toNotify
            creditor, // The owner
            address(this)
        );

        // Fund nota
        fundHelper(notaId, reversibleRelease, faceValue, debtor, creditor);
    }

    function testFundTransferInvoice(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        writeAssumptions(debtor, faceValue, creditor);

        (uint256 notaId, ReversibleRelease reversibleRelease) = writeHelper(
            creditor, // Who the caller should be
            faceValue, // Face value of invoice
            0, // escrowed amount
            0, // instant amount
            debtor, // toNotify
            creditor, // The owner
            address(this)
        );

        // Fund nota
        fundHelper(notaId, reversibleRelease, faceValue, debtor, creditor);

        vm.prank(creditor);
        REGISTRAR.safeTransferFrom(
            creditor,
            address(1),
            notaId,
            abi.encode(bytes32("")) // transfer data
        );
    }

    function testCashPayment(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        writeAssumptions(debtor, faceValue, creditor);
        (
            uint256 notaId /*ReversibleRelease reversibleRelease*/,

        ) = writeHelper(
                debtor, // Caller
                faceValue, // Face value
                faceValue, // escrowed
                0, // instant
                creditor, // toNotify
                creditor, // Owner
                address(this)
            );

        uint256 balanceBefore = dai.balanceOf(creditor);
        vm.prank(address(this));
        REGISTRAR.cash(
            notaId, //
            faceValue, // amount to cash
            creditor, // to
            bytes(abi.encode(""))
        );

        assertTrue(dai.balanceOf(creditor) - balanceBefore == faceValue);
    }

    function testReversePayment(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        writeAssumptions(debtor, faceValue, creditor);

        (
            uint256 notaId /*ReversibleRelease reversibleRelease*/,

        ) = writeHelper(
                debtor, // Who the caller should be
                faceValue, // Face value of invoice
                faceValue, // escrowed amount
                0, // instant amount
                creditor, // toNotify
                creditor, // The owner
                address(this)
            );

        uint256 balanceBefore = dai.balanceOf(creditor);
        vm.prank(address(this));
        REGISTRAR.cash(
            notaId, //
            faceValue, // amount
            debtor, // to
            bytes(abi.encode(""))
        );

        assertTrue(
            balanceBefore + faceValue == dai.balanceOf(debtor),
            "Incorrect cash out"
        );
    }

    function testCashInvoice(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        writeAssumptions(debtor, faceValue, creditor);

        (uint256 notaId, ReversibleRelease reversibleRelease) = writeHelper(
            creditor, // Who the caller should be
            faceValue, // Face value of invoice
            0, // escrowed amount
            0, // instant amount
            debtor, // toNotify
            creditor, // The owner
            address(this)
        );

        // Fund nota
        fundHelper(notaId, reversibleRelease, faceValue, debtor, creditor);

        uint256 balanceBefore = dai.balanceOf(creditor);
        vm.prank(address(this));
        REGISTRAR.cash(
            notaId,
            faceValue, // amount to cash
            creditor, // to
            bytes(abi.encode(address(0))) // dappOperator
        );

        assertTrue(balanceBefore + faceValue == dai.balanceOf(creditor));
    }

    function testReverseInvoice(
        address debtor,
        uint256 faceValue,
        address creditor
    ) public {
        writeAssumptions(debtor, faceValue, creditor);

        (uint256 notaId, ReversibleRelease reversibleRelease) = writeHelper(
            creditor, // Who the caller should be
            faceValue, // Face value of invoice
            0, // escrowed amount
            0, // instant amount
            debtor, // toNotify
            creditor, // The owner
            address(this)
        );

        // Fund nota
        fundHelper(notaId, reversibleRelease, faceValue, debtor, creditor);
    }
}
