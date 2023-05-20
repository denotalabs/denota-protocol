// // // SPDX-License-Identifier: BUSL-1.1
// pragma solidity ^0.8.16;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";
// import "./mock/erc20.sol";
// import {CheqRegistrar} from "../src/CheqRegistrar.sol";
// import {DataTypes} from "../src/libraries/DataTypes.sol";
// import {Milestones} from "../src/modules/Milestones.sol";

// // TODO add fail tests
// contract MilestonesTest is Test {
//     CheqRegistrar public REGISTRAR;
//     TestERC20 public dai;
//     TestERC20 public usdc;
//     uint256 public immutable tokensCreated = 1_000_000_000_000e18;

//     function isContract(address _addr) public view returns (bool) {
//         uint32 size;
//         assembly {
//             size := extcodesize(_addr)
//         }
//         return (size > 0);
//     }

//     function setUp() public {
//         // sets up the registrar and ERC20s
//         REGISTRAR = new CheqRegistrar(); // ContractTest is the owner
//         dai = new TestERC20(tokensCreated, "DAI", "DAI"); // Sends ContractTest the dai
//         usdc = new TestERC20(0, "USDC", "USDC");
//         // REGISTRAR.whitelistToken(address(dai), true);
//         // REGISTRAR.whitelistToken(address(usdc), true);

//         vm.label(msg.sender, "Alice");
//         vm.label(address(this), "TestContract");
//         vm.label(address(dai), "TestDai");
//         vm.label(address(usdc), "TestUSDC");
//         vm.label(address(REGISTRAR), "CheqRegistrarContract");
//     }

//     function whitelist(address module) public {
//         // Whitelists tokens, rules, modules
//         // REGISTRAR.whitelistRule(rule, true);
//         REGISTRAR.whitelistModule(module, false, true, "Milestones"); // Whitelist bytecode
//     }

//     /*///////////////////////// SETUP /////////////////////////////*/
//     function testWhitelistToken() public {
//         address daiAddress = address(dai);
//         vm.prank(address(this));

//         // Whitelist tokens
//         assertFalse(
//             REGISTRAR.tokenWhitelisted(daiAddress),
//             "Unauthorized whitelist"
//         );
//         REGISTRAR.whitelistToken(daiAddress, true, "DAI");
//         assertTrue(
//             REGISTRAR.tokenWhitelisted(daiAddress),
//             "Whitelisting failed"
//         );
//         REGISTRAR.whitelistToken(daiAddress, false, "DAI");
//         assertFalse(
//             REGISTRAR.tokenWhitelisted(daiAddress),
//             "Un-whitelisting failed"
//         );

//         // Whitelist rules
//         // MilestonesRules milestonesRules = new MilestonesRules();
//         // address milestonesRulesAddress = address(milestonesRules);
//         // assertFalse(
//         //     REGISTRAR.ruleWhitelisted(milestonesRulesAddress),
//         //     "Unauthorized whitelist"
//         // );
//         // REGISTRAR.whitelistRule(milestonesRulesAddress, true); // whitelist bytecode, not address
//         // assertTrue(
//         //     REGISTRAR.ruleWhitelisted(milestonesRulesAddress),
//         //     "Whitelisting failed"
//         // );
//         // REGISTRAR.whitelistRule(milestonesRulesAddress, false);
//         // assertFalse(
//         //     REGISTRAR.ruleWhitelisted(milestonesRulesAddress),
//         //     "Un-whitelisting failed"
//         // );
//         // REGISTRAR.whitelistRule(milestonesRulesAddress, true); // whitelist bytecode, not address

//         // Whitelist module
//         Milestones milestones = new Milestones(
//             address(REGISTRAR),
//             DataTypes.WTFCFees(0, 0, 0, 0),
//             "ipfs://yourmemos.com/"
//         );
//         address milestonesAddress = address(milestones);
//         (bool addressWhitelisted, bool bytecodeWhitelisted) = REGISTRAR
//             .moduleWhitelisted(milestonesAddress);
//         assertFalse(
//             addressWhitelisted || bytecodeWhitelisted,
//             "Unauthorized whitelist"
//         );
//         REGISTRAR.whitelistModule(milestonesAddress, true, false, "Milestones"); // whitelist bytecode, not address
//         (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(
//             milestonesAddress
//         );
//         assertTrue(
//             addressWhitelisted || bytecodeWhitelisted,
//             "Whitelisting failed"
//         );
//         REGISTRAR.whitelistModule(
//             milestonesAddress,
//             false,
//             false,
//             "Milestones"
//         );
//         (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(
//             milestonesAddress
//         );
//         assertFalse(
//             addressWhitelisted || bytecodeWhitelisted,
//             "Un-whitelisting failed"
//         );
//     }

//     function setUpMilestones() public returns (Milestones) {
//         // Deploy and whitelist module
//         Milestones milestones = new Milestones(
//             address(REGISTRAR),
//             DataTypes.WTFCFees(0, 0, 0, 0),
//             "ipfs://yourmemos.com/"
//         );
//         REGISTRAR.whitelistModule(
//             address(milestones),
//             true,
//             false,
//             "Milestones"
//         );
//         vm.label(address(milestones), "Milestones");
//         return milestones;
//     }

//     /*//////////////////////// MODULE TESTS ///////////////////////*/
//     function calcFee(
//         uint256 fee,
//         uint256 amount
//     ) public pure returns (uint256) {
//         return (amount * fee) / 10_000;
//     }

//     function registrarWriteBefore(address caller, address owner) public {
//         assertTrue(
//             REGISTRAR.balanceOf(caller) == 0,
//             "Caller already had a cheq"
//         );
//         assertTrue(
//             REGISTRAR.balanceOf(owner) == 0,
//             "Recipient already had a cheq"
//         );
//         assertTrue(REGISTRAR.totalSupply() == 0, "Cheq supply non-zero");
//     }

//     function registrarWriteAfter(
//         uint256 cheqId,
//         uint256 escrowed,
//         address owner,
//         address module
//     ) public {
//         assertTrue(
//             REGISTRAR.totalSupply() == 1,
//             "Cheq supply didn't increment"
//         );
//         assertTrue(
//             REGISTRAR.ownerOf(cheqId) == owner,
//             "`owner` isn't owner of cheq"
//         );
//         assertTrue(
//             REGISTRAR.balanceOf(owner) == 1,
//             "Owner balance didn't increment"
//         );

//         // CheqRegistrar wrote correctly to its storage
//         // assertTrue(REGISTRAR.cheqDrawer(cheqId) == drawer, "Incorrect drawer");
//         // assertTrue(
//         //     REGISTRAR.cheqRecipient(cheqId) == recipient,
//         //     "Incorrect recipient"
//         // );
//         assertTrue(
//             REGISTRAR.cheqCurrency(cheqId) == address(dai),
//             "Incorrect token"
//         );
//         // assertTrue(REGISTRAR.cheqAmount(cheqId) == amount, "Incorrect amount");
//         assertTrue(
//             REGISTRAR.cheqEscrowed(cheqId) == escrowed,
//             "Incorrect escrow"
//         );
//         assertTrue(
//             address(REGISTRAR.cheqModule(cheqId)) == module,
//             "Incorrect module"
//         );
//     }

//     function calcTotalFees(
//         CheqRegistrar registrar,
//         Milestones milestones,
//         uint256 escrowed,
//         uint256 directAmount
//     ) public view returns (uint256) {
//         DataTypes.WTFCFees memory fees = milestones.getFees(address(0));
//         uint256 moduleFee = calcFee(fees.writeBPS, directAmount + escrowed);
//         console.log("ModuleFee: ", moduleFee);
//         uint256 totalWithFees = escrowed + directAmount + moduleFee;
//         console.log(escrowed + directAmount, "-->", totalWithFees);
//         return totalWithFees;
//     }

//     function writeConditions(
//         address caller,
//         uint256 firstMilestone,
//         uint256 secondMilestone,
//         address debtor,
//         address creditor
//     ) public view returns (bool) {
//         uint256 helper1 = firstMilestone >> 4;
//         uint256 helper2 = secondMilestone >> 4;
//         uint256 intMax = type(uint256).max >> 4;
//         if (helper1 + helper2 >= intMax) return false;
//         uint256 amount = firstMilestone + secondMilestone;
//         return
//             (amount != 0) &&
//             (amount <= tokensCreated) &&
//             (secondMilestone != 0) &&
//             (debtor != creditor) &&
//             (debtor != address(0) && creditor != address(0)) &&
//             !isContract(creditor); // Don't send cheqs to non-ERC721Reciever contracts
//     }

//     function _writePayment(
//         Milestones milestones,
//         uint256 firstMilestone, // instant
//         uint256 secondMilestone, // escrowed
//         address caller,
//         address owner,
//         bytes memory initData
//     ) public returns (uint256) {
//         uint256 totalWithFees = calcTotalFees(
//             REGISTRAR,
//             milestones,
//             firstMilestone,
//             secondMilestone
//         );
//         vm.prank(caller);
//         dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
//         dai.transfer(caller, totalWithFees);
//         vm.assume(dai.balanceOf(caller) >= totalWithFees);

//         console.log(secondMilestone, totalWithFees);
//         vm.prank(caller);
//         return
//             REGISTRAR.write(
//                 address(dai),
//                 secondMilestone, // escrowed
//                 firstMilestone, // instant
//                 owner,
//                 address(milestones),
//                 initData
//             ); // Sets caller as owner
//     }

//     function writeHelper(
//         address caller,
//         uint256 secondMilestone, // escrowed
//         uint256 firstMilestone, // instant
//         address toNotify,
//         address owner
//     ) public returns (uint256, Milestones) {
//         Milestones milestones = setUpMilestones();
//         REGISTRAR.whitelistToken(address(dai), true, "Milestones");
//         registrarWriteBefore(caller, toNotify);

//         uint256[] memory milestoneAmounts = new uint256[](2);
//         milestoneAmounts[0] = firstMilestone;
//         milestoneAmounts[1] = secondMilestone; // milestoneAmounts[2] = 10;
//         bytes memory initData = abi.encode(
//             toNotify,
//             address(this),
//             bytes32(keccak256("this is a hash")),
//             milestoneAmounts
//         );

//         uint256 cheqId;
//         if (caller == owner) {
//             vm.prank(caller);
//             cheqId = REGISTRAR.write(
//                 address(dai),
//                 0,
//                 0,
//                 caller,
//                 address(milestones),
//                 initData
//             ); // Sets caller as owner
//             registrarWriteAfter(
//                 cheqId,
//                 0, // escrowed
//                 owner,
//                 address(milestones)
//             );
//         } else {
//             cheqId = _writePayment(
//                 milestones,
//                 firstMilestone,
//                 secondMilestone,
//                 caller,
//                 owner,
//                 initData
//             );
//             registrarWriteAfter(
//                 cheqId,
//                 secondMilestone, // escrowed
//                 owner,
//                 address(milestones)
//             );
//         }

//         return (cheqId, milestones);
//     }

//     function fundHelper(
//         uint256 cheqId,
//         address debtor,
//         uint256 escrowed,
//         uint256 instant,
//         Milestones milestones
//     ) public {
//         uint256 totalWithFees = calcTotalFees(
//             REGISTRAR,
//             milestones,
//             escrowed, // escrowed amount
//             instant // instant amount
//         );
//         vm.prank(debtor);
//         dai.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
//         dai.transfer(debtor, totalWithFees);
//         vm.assume(dai.balanceOf(debtor) >= totalWithFees);
//         uint256 debtorBalanceBefore = dai.balanceOf(debtor);

//         bytes memory fundData = abi.encode(bytes32(""));
//         vm.prank(debtor);
//         REGISTRAR.fund(cheqId, escrowed, instant, fundData); // Send direct amount
//         assertTrue(
//             debtorBalanceBefore - (escrowed + instant) == dai.balanceOf(debtor),
//             "Didnt decrement balance"
//         );
//     }

//     function testWritePay(
//         address creditor,
//         uint256 firstMilestone,
//         uint256 secondMilestone,
//         address debtor
//     ) public {
//         vm.assume(
//             writeConditions(
//                 debtor, // caller
//                 firstMilestone,
//                 secondMilestone,
//                 debtor,
//                 creditor
//             )
//         );

//         // First milestone must be escrowed (or instant and second escrowed)
//         (uint256 cheqId, Milestones milestones) = writeHelper(
//             debtor, // caller
//             secondMilestone, // escrowed amount
//             firstMilestone, // instant amount
//             creditor, // toNotify
//             creditor // The owner
//         );

//         // ICheqModule wrote correctly to it's storage
//         string memory tokenURI = REGISTRAR.tokenURI(cheqId);
//         console.log("TokenURI: ");
//         console.log(tokenURI);
//     }

//     function testWriteInvoice(
//         address creditor,
//         uint256 secondMilestone,
//         uint256 firstMilestone,
//         address debtor
//     ) public {
//         vm.assume(
//             writeConditions(
//                 creditor, // caller
//                 firstMilestone,
//                 secondMilestone,
//                 debtor,
//                 creditor
//             )
//         );

//         // First milestone must be escrowed (or instant and second escrowed)
//         (uint256 cheqId, Milestones milestones) = writeHelper(
//             creditor, // caller
//             secondMilestone, // instant amount
//             firstMilestone, // escrowed amount
//             debtor, // toNotify
//             creditor // The owner
//         );

//         // ICheqModule wrote correctly to it's storage
//         string memory tokenURI = REGISTRAR.tokenURI(cheqId);
//         console.log("TokenURI: ");
//         console.log(tokenURI);
//     }

//     function testFundInvoice(
//         address creditor,
//         uint256 secondMilestone,
//         uint256 firstMilestone,
//         address debtor
//     ) public {
//         vm.assume(
//             writeConditions(
//                 creditor, // caller
//                 firstMilestone,
//                 secondMilestone,
//                 debtor,
//                 creditor
//             )
//         );
//         // First milestone must be escrowed (or instant and second escrowed)
//         (uint256 cheqId, Milestones milestones) = writeHelper(
//             creditor, // caller
//             secondMilestone, // instant amount
//             firstMilestone, // escrowed amount
//             debtor, // debtor in this case
//             creditor // The owner
//         );

//         fundHelper(
//             cheqId,
//             debtor, // debtor
//             secondMilestone, // escrowed
//             firstMilestone, // instant
//             milestones
//         );
//     }

//     function testCashPay(
//         address creditor,
//         uint256 secondMilestone,
//         uint256 firstMilestone,
//         address debtor
//     ) public {
//         vm.assume(
//             writeConditions(
//                 creditor, // caller
//                 firstMilestone,
//                 secondMilestone,
//                 debtor,
//                 creditor
//             )
//         );

//         // First milestone must be escrowed (or instant and second escrowed)
//         (uint256 cheqId, Milestones milestones) = writeHelper(
//             debtor, // caller
//             secondMilestone, // escrowed amount
//             firstMilestone, // instant amount
//             creditor, // toNotify
//             creditor // The owner
//         ); // Instant pay the first, escrow second

//         fundHelper(cheqId, debtor, 0, 0, milestones); // release second

//         bytes memory cashData = abi.encode(1, address(0)); // cash second milestone
//         vm.prank(creditor);
//         REGISTRAR.cash(cheqId, secondMilestone, creditor, cashData);
//     }

//     function testCashInvoice(
//         address creditor,
//         uint256 secondMilestone,
//         uint256 firstMilestone,
//         address debtor
//     ) public {
//         vm.assume(
//             writeConditions(
//                 creditor, // caller
//                 firstMilestone,
//                 secondMilestone,
//                 debtor,
//                 creditor
//             )
//         );

//         // First milestone must be escrowed (or instant and second escrowed)
//         (uint256 cheqId, Milestones milestones) = writeHelper(
//             creditor, // caller
//             secondMilestone, // instant amount
//             firstMilestone, // escrowed amount
//             debtor, // debtor in this case
//             creditor // The owner
//         );

//         fundHelper(cheqId, debtor, secondMilestone, firstMilestone, milestones);
//         fundHelper(cheqId, debtor, 0, 0, milestones);

//         bytes memory cashData = abi.encode(1, address(0)); // cash second milestone
//         vm.prank(creditor);
//         REGISTRAR.cash(cheqId, secondMilestone, creditor, cashData);
//     }
// }

// // function testCashPay(address caller, uint256 amount, address drawer, address recipient) public {
// //     vm.assume(amount != 0 && amount <= tokensCreated);
// //     (address drawer, uint256 escrowed, address owner) = (caller, amount, caller);
// //     vm.assume(caller != address(0) && recipient != address(0) && !isContract(owner));
// //     vm.assume(drawer != recipient);

// //     (uint256 cheqId, ) = writeHelper(caller, amount, escrowed, drawer, recipient, owner);
// //     bytes memory cashData =  abi.encode(bytes32(""));

// //     vm.prank(owner);
// //     REGISTRAR.cash(cheqId, escrowed, owner, cashData);
// // }

// // function testTransferPay(address caller, uint256 amount, address recipient) public {
// //     vm.assume(amount != 0 && amount <= tokensCreated);
// //     (address drawer, uint256 directAmount, address owner) = (caller, amount, recipient);
// //     vm.assume(caller != address(0) && recipient != address(0) && !isContract(owner));
// //     vm.assume(drawer != recipient);

// //     (uint256 cheqId, Milestones milestones) = writeHelper(caller, amount, directAmount, drawer, recipient, owner);
// //     vm.expectRevert(bytes("Rule: Disallowed"));
// //     REGISTRAR.transferFrom(owner, drawer, cheqId);
// // }

// // function testTransferInvoice(address caller, uint256 amount, address recipient) public {
// //     vm.assume(amount != 0 && amount <= tokensCreated);
// //     (address drawer, uint256 directAmount, address owner) = (caller, amount, caller);
// //     vm.assume(caller != address(0) && recipient != address(0) && !isContract(owner));
// //     vm.assume(drawer != recipient);

// //     (uint256 cheqId, Milestones milestones) = writeHelper(caller, amount, directAmount, drawer, recipient, owner);
// //     vm.expectRevert(bytes("Rule: Disallowed"));
// //     REGISTRAR.transferFrom(owner, drawer, cheqId);
// // }

// // function testFundPay(address caller, uint256 amount, address drawer, address recipient) public {
// //     vm.assume(amount != 0 && amount <= tokensCreated);
// //     (address drawer, uint256 escrowed, address owner) = (caller, amount, caller);
// //     vm.assume(caller != address(0) && recipient != address(0) && !isContract(owner));
// //     vm.assume(drawer != recipient);

// //     (uint256 cheqId, Milestones milestones) = writeHelper(caller, amount, escrowed, drawer, recipient, owner);
// //     bytes memory fundData =  abi.encode(bytes32(""));

// //     vm.expectRevert(bytes("Rule: Only recipient"));
// //     REGISTRAR.fund(cheqId, 0, amount, fundData);
// // }
