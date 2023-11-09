// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// import "./mock/erc20.sol";
// import "forge-std/Test.sol";
// import "forge-std/console.sol";
// import {DataTypes} from "src/contracts/libraries/DataTypes.sol";
// import {NotaRegistrar} from "src/contracts/NotaRegistrar.sol";
// import {Marketplace} from "src/contracts/Modules/Marketplace.sol";
// import {AllTrueRules} from "src/contracts/rules/AllTrueRules.sol";

// enum Status {
//     Waiting,
//     Ready,
//     InProgress,
//     Disputing,
//     Resolved,
//     Finished
// }
// struct Milestone {
//     uint256 price; // Amount the milestone is worth
//     bool workerFinished; // Could pack these bools more
//     bool clientReleased;
// }
// struct Invoice {
//     uint256 startTime;
//     uint256 currentMilestone;
//     Status workerStatus;
//     Status clientStatus;
//     // bytes32 documentHash;
//     Milestone[] milestones;
// }

// contract ContractTest is Test {
//     //     NotaRegistrar public REGISTRAR;
//     //     TestERC20 public dai;
//     //     TestERC20 public usdc;
//     //     uint256 public immutable tokensCreated = 1_000_000_000_000e18;
//     //     function isContract(address _addr) public view returns (bool){
//     //         uint32 size;
//     //         assembly {size := extcodesize(_addr)}
//     //         return (size > 0);
//     //     }
//     //     function setUp() public {  // sets up the registrar and ERC20s
//     //         REGISTRAR = new NotaRegistrar(WTFCFees(0,0,0,0));  // ContractTest is the owner
//     //         dai = new TestERC20(tokensCreated, "DAI", "DAI");  // Sends ContractTest the dai
//     //         usdc = new TestERC20(0, "USDC", "USDC");
//     //         // REGISTRAR.whitelistToken(address(dai), true);
//     //         // REGISTRAR.whitelistToken(address(usdc), true);
//     //         vm.label(msg.sender, "Alice");
//     //         vm.label(address(this), "TestContract");
//     //         vm.label(address(dai), "TestDai");
//     //         vm.label(address(usdc), "TestUSDC");
//     //         vm.label(address(REGISTRAR), "NotaRegistrarContract");
//     //     }
//     //     // function whitelist(address rule, address module) public {  // Whitelists tokens, rules, modules
//     //     //     REGISTRAR.whitelistRule(rule, true);
//     //     //     REGISTRAR.whitelistModule(module, false, true);  // Whitelist bytecode
//     //     // }
//     //     /*//////////////////////////////////////////////////////////////
//     //                                CHEQ TESTS
//     //     //////////////////////////////////////////////////////////////*/
//     //     // function testWhitelistToken() public {
//     //     //     address daiAddress = address(dai);
//     //     //     vm.prank(address(this));
//     //     //     assertFalse(REGISTRAR.tokenWhitelisted(daiAddress), "Unauthorized whitelist");
//     //     //     REGISTRAR.whitelistToken(daiAddress, true);
//     //     //     assertTrue(REGISTRAR.tokenWhitelisted(daiAddress), "Whitelisting failed");
//     //     //     REGISTRAR.whitelistToken(daiAddress, false);
//     //     //     assertFalse(REGISTRAR.tokenWhitelisted(daiAddress), "Un-whitelisting failed");
//     //     //     AllTrueRules allRules = new AllTrueRules();
//     //     //     address allRulesAddress = address(allRules);
//     //     //     assertFalse(REGISTRAR.ruleWhitelisted(allRulesAddress), "Unauthorized whitelist");
//     //     //     REGISTRAR.whitelistRule(allRulesAddress, true); // whitelist bytecode, not address
//     //     //     assertTrue(REGISTRAR.ruleWhitelisted(allRulesAddress), "Whitelisting failed");
//     //     //     REGISTRAR.whitelistRule(allRulesAddress, false);
//     //     //     assertFalse(REGISTRAR.ruleWhitelisted(allRulesAddress), "Un-whitelisting failed");
//     //     //     REGISTRAR.whitelistRule(allRulesAddress, true); // whitelist bytecode, not address
//     //     //     Marketplace market = new Marketplace(address(REGISTRAR), allRulesAddress, allRulesAddress, allRulesAddress, allRulesAddress, allRulesAddress, 100, "MyMarket");  // How to test successful deployment
//     //     //     address marketAddress = address(market);
//     //     //     (bool addressWhitelisted, bool bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(marketAddress);
//     //     //     assertFalse(addressWhitelisted || bytecodeWhitelisted, "Unauthorized whitelist");
//     //     //     REGISTRAR.whitelistModule(marketAddress, true, false); // whitelist bytecode, not address
//     //     //     (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(marketAddress);
//     //     //     assertTrue(addressWhitelisted || bytecodeWhitelisted, "Whitelisting failed");
//     //     //     REGISTRAR.whitelistModule(marketAddress, false, false);
//     //     //     (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(marketAddress);
//     //     //     assertFalse(addressWhitelisted || bytecodeWhitelisted, "Un-whitelisting failed");
//     //     // }
//     //     // function testFailWhitelist(address caller) public {
//     //     //     vm.assume(caller == address(0));  // Deployer can whitelist, test others accounts
//     //     //     Marketplace market = new Marketplace(REGISTRAR);
//     //     //     vm.prank(caller);
//     //     //     REGISTRAR.whitelistModule(market, true);
//     //     //     assertFalse(REGISTRAR.moduleWhitelisted(address(this), market), "Unauthorized whitelist");
//     //     // }
//     //     function setUpMarketplace() public returns (Marketplace){  // Deploy and whitelist timelock module
//     //         AllTrueRules allTrueRules = new AllTrueRules();
//     //         address allTrueAddress = address(allTrueRules);
//     //         REGISTRAR.whitelistRule(allTrueAddress, true);
//     //         Marketplace market = new Marketplace(address(REGISTRAR), allTrueAddress, allTrueAddress, allTrueAddress, allTrueAddress, allTrueAddress, WTFCFees(0,0,0,0), "MyMarket");
//     //         REGISTRAR.whitelistModule(address(market), true, false);
//     //         vm.label(address(market), "Marketplace");
//     //         return market;
//     //     }
//     //     /*//////////////////////////////////////////////////////////////
//     //                             MODULE TESTS
//     //     //////////////////////////////////////////////////////////////*/
//     //     function calcFee(uint256 fee, uint256 amount) public pure returns(uint256){
//     //         uint256 FEE = (amount * fee) / 10_000;
//     //         return FEE;
//     //     }
//     //     function notaWriteCondition(address caller, uint256 amount, address recipient/*, uint256 duration*/) public view returns(bool){
//     //         return amount <= tokensCreated &&   // Can't use more token than created
//     //                caller != recipient &&  // Don't self send
//     //                caller != address(0) &&  // Don't vm.prank from address(0)
//     //                recipient != address(0) &&   // Can't send to, or transact from, address(0)
//     //                !isContract(recipient);// &&  // Don't send tokens to non-ERC721Reciever contracts
//     //             //    duration < type(uint).max &&  // Causes overflow
//     //             //    (duration >> 2) + (block.timestamp >> 2) <= (type(uint).max >> 2) ; // Causes overflow
//     //     }
//     //     function testWritenota(address caller, uint256 amount, address recipient) public {
//     //         vm.assume(notaWriteCondition(caller, amount, recipient));
//     //         vm.assume(amount > 0);
//     //         REGISTRAR.whitelistToken(address(dai), true);
//     //         (uint256 writeFeeBPS, , , ) = REGISTRAR.getFees();
//     //         Marketplace market = setUpMarketplace();
//     //         market.whitelistToken(address(dai), true);
//     //         (uint256 marketWriteFeeBPS, , , ) = market.getFees();
//     //         uint256 totalWithFees;
//     //         {
//     //             uint256 registrarFee = calcFee(writeFeeBPS, amount);
//     //             console.log("RegistrarFee: ", registrarFee);
//     //             uint256 moduleFee =calcFee(marketWriteFeeBPS, amount);
//     //             console.log("ModuleFee: ", moduleFee);
//     //             totalWithFees = registrarFee + moduleFee + amount;
//     //         }
//     //         console.log(amount, "-->", totalWithFees);
//     //         vm.prank(caller);
//     //         dai.approve(address(REGISTRAR), totalWithFees);  // Need to get the fee amounts beforehand
//     //         dai.transfer(caller, totalWithFees);
//     //         assertTrue(REGISTRAR.balanceOf(caller) == 0, "Caller already had a nota");
//     //         assertTrue(REGISTRAR.balanceOf(recipient) == 0, "Recipient already had a nota");
//     //         assertTrue(REGISTRAR.totalSupply() == 0, "nota supply non-zero");
//     //         Nota memory nota = Nota({
//     //             currency: address(dai),
//     //             amount: amount,
//     //             escrowed: amount,
//     //             drawer: caller,
//     //             recipient: recipient,
//     //             module: address(market),
//     //             mintTimestamp: block.timestamp
//     //         });
//     //         uint256[] memory prices = new uint256[](3);
//     //         prices[0] = 10; prices[1] = 12; prices[2] = 15;  // TODO dynamic
//     //         bytes memory initData = abi.encode(prices);
//     //         vm.prank(caller);
//     //         uint256 notaId = REGISTRAR.write(nota, initData, caller);
//     //         assertTrue(REGISTRAR.totalSupply() == 1, "nota supply didn't increment");
//     //         assertTrue(REGISTRAR.ownerOf(notaId) == caller, "Recipient isn't owner");
//     //         assertTrue(REGISTRAR.balanceOf(caller) == 1, "Sender got a nota");
//     //         // assertTrue(REGISTRAR.balanceOf(recipient) == 1, "Recipient didnt get a nota");
//     //         // NotaRegistrar wrote correctly to its storage
//     //         assertTrue(REGISTRAR.notaDrawer(notaId) == caller, "Incorrect drawer");
//     //         assertTrue(REGISTRAR.notaRecipient(notaId) == recipient, "Incorrect recipient");
//     //         assertTrue(REGISTRAR.notaCurrency(notaId) == address(dai), "Incorrect token");
//     //         assertTrue(REGISTRAR.notaAmount(notaId) == amount, "Incorrect amount");
//     //         assertTrue(REGISTRAR.notaEscrowed(notaId) == amount, "Incorrect escrow");
//     //         assertTrue(address(REGISTRAR.notaModule(notaId)) == address(market), "Incorrect module");
//     //         // INotaModule wrote correctly to it's storage
//     //         (
//     //             uint256 startTime,
//     //             uint256 currentMilestone,
//     //             uint256 totalMilestones,
//     //             Marketplace.Status workerStatus,
//     //             Marketplace.Status clientStatus,
//     //             bytes32 documentHash
//     //         ) = market.invoices(notaId);
//     //         Marketplace.Milestone[] memory milestones = market.getMilestones(notaId);
//     //         // console.log(startTime, currentMilestone, workerStatus, clientStatus);
//     //         console.log("TotalMilestones: ");
//     //         console.log(totalMilestones);
//     //         for (uint256 i = 0; i < milestones.length; i++) { console.log(milestones[i].price); }
//     //         // assertTrue(market.notaInspectionPeriod(notaId) == duration, "Incorrect expired");
//     //     }
//     // //     function testWriteInvoice(address caller, address recipient, uint256 duration, uint256 amount) public {
//     // //         vm.assume(amount != 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(duration < type(uint256).max);
//     // //         assertTrue(REGISTRAR.balanceOf(caller) == 0, "Caller already had a nota");
//     // //         assertTrue(REGISTRAR.balanceOf(recipient) == 0);
//     // //         assertTrue(REGISTRAR.totalSupply() == 0, "nota supply non-zero");
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         vm.prank(caller);
//     // //         uint256 notaId = sstl.writenota(dai, amount, 0, recipient, duration);
//     // //         assertTrue(REGISTRAR.deposits(caller, dai) == 0, "Writer gained a deposit");
//     // //         assertTrue(REGISTRAR.totalSupply() == 1, "nota supply didn't increment");
//     // //         assertTrue(REGISTRAR.balanceOf(caller) == 1, "Invoicer didn't get a nota");
//     // //         assertTrue(REGISTRAR.balanceOf(recipient) == 0, "Recipient gained a nota");
//     // //         assertTrue(REGISTRAR.ownerOf(notaId) == caller, "Invoicer isn't owner");
//     // //         // INotaModule wrote correctly to NotaRegistrar storage
//     // //         assertTrue(REGISTRAR.notaAmount(notaId) == amount, "Incorrect amount");
//     // //         assertTrue(REGISTRAR.notaToken(notaId) == dai, "Incorrect token");
//     // //         assertTrue(REGISTRAR.notaDrawer(notaId) == caller, "Incorrect drawer");
//     // //         assertTrue(REGISTRAR.notaRecipient(notaId) == recipient, "Incorrect recipient");
//     // //         assertTrue(address(nota.notaModule(notaId)) == address(sstl), "Incorrect module");
//     // //         // INotaModule wrote correctly to it's storage
//     // //         assertTrue(sstl.notaFunder(notaId) == recipient, "nota reciever is same as on nota");
//     // //         assertTrue(sstl.notaReceiver(notaId) == caller, "nota reciever is same as on SSTL");
//     // //         assertTrue(sstl.notaCreated(notaId) == block.timestamp, "nota created not at block.timestamp");
//     // //         assertTrue(sstl.notaInspectionPeriod(notaId) == duration, "Expired");
//     // //     }
//     // //     function testFailWritenota(address caller, uint256 amount, address recipient, uint256 duration) public {
//     // //         vm.assume(amount <= dai.totalSupply());
//     // //         vm.assume(amount > 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         // Can't write nota without a deposit on crx
//     // //         vm.prank(caller);
//     // //         sstl.writenota(dai, amount, amount, recipient, duration);
//     // //         // Can't write notaues with insufficient balance
//     // //         depositHelper(amount, caller);
//     // //         sstl.writenota(dai, amount, amount + 1, recipient, duration);  // Not enough escrow and amount!=escrow && escrow>0
//     // //         sstl.writenota(dai, amount + 1, amount + 1, recipient, duration);  // Not enough escrow
//     // //         // Can't write directly from nota
//     // //         vm.prank(caller);
//     // //         nota.write(caller, caller, recipient, dai, amount, amount, recipient);
//     // //         // Can't write a 0 amount nota??
//     // //         vm.prank(caller);
//     // //         sstl.writenota(dai, 0, amount, recipient, duration);
//     // //         // Can't write a nota with a higher escrow than amount??
//     // //         vm.prank(caller);
//     // //         sstl.writenota(dai, amount, amount + 1, recipient, duration);
//     // //     }
//     // //     function helpernotaInfo(uint256 notaId, uint256 amount, address sender, address recipient, SelfSignTimeLock sstl, uint256 duration) public {
//     // //         // INotaModule wrote correctly to NotaRegistrar storage
//     // //         assertTrue(nota.notaAmount(notaId) == amount, "Incorrect amount");
//     // //         assertTrue(nota.notaToken(notaId) == dai, "Incorrect token");
//     // //         assertTrue(nota.notaDrawer(notaId) == sender, "Incorrect drawer");
//     // //         assertTrue(nota.notaRecipient(notaId) == recipient, "Incorrect recipient");
//     // //         assertTrue(address(nota.notaModule(notaId)) == address(sstl), "Incorrect module");
//     // //         // INotaModule wrote correctly to it's storage
//     // //         if (sstl.notaFunder(notaId) == sender){  // nota
//     // //             assertTrue(nota.notaEscrowed(notaId) == amount, "Incorrect escrowed amount");
//     // //             assertTrue(sstl.notaFunder(notaId) == nota.notaDrawer(notaId), "nota funder is not the sender");
//     // //             assertTrue(sstl.notaReceiver(notaId) == recipient, "nota reciever is not recipient");
//     // //         } else {  // Invoice
//     // //             assertTrue(nota.notaEscrowed(notaId) == 0, "Incorrect escrowed amount");
//     // //             assertTrue(sstl.notaFunder(notaId) == nota.notaRecipient(notaId), "nota reciever is same as on nota");
//     // //             assertTrue(sstl.notaReceiver(notaId) == nota.notaDrawer(notaId), "nota reciever is same as on SSTL");
//     // //         }
//     // //         assertTrue(sstl.notaCreated(notaId) == block.timestamp, "nota created not at block.timestamp");
//     // //         assertTrue(sstl.notaInspectionPeriod(notaId) == duration, "Expired");
//     // //     }
//     // //     function writeHelper(address sender, uint256 amount, uint256 escrow, address recipient, uint256 duration, SelfSignTimeLock sstl) public returns(uint256){
//     // //         uint256 senderBalanceOf = nota.balanceOf(sender);
//     // //         uint256 recipientBalanceOf = nota.balanceOf(recipient);
//     // //         uint256 notaSupply = nota.totalSupply();
//     // //         assertTrue(nota.balanceOf(sender) == 0, "Caller already got a nota");
//     // //         assertTrue(nota.balanceOf(recipient) == 0);
//     // //         vm.prank(sender);
//     // //         uint256 notaId = sstl.writenota(dai, amount, escrow, recipient, duration);  // Change dai to arbitrary token
//     // //         helpernotaInfo(notaId, amount, sender, recipient, sstl, duration);
//     // //         if (escrow == amount && amount != 0){ // nota
//     // //             assertTrue(nota.deposits(sender, dai) == 0, "Writer gained a deposit");
//     // //             assertTrue(nota.balanceOf(sender) == senderBalanceOf, "Recipient gained a nota");
//     // //             assertTrue(nota.balanceOf(recipient) == recipientBalanceOf + 1, "Recipient didnt get a nota");
//     // //             assertTrue(nota.ownerOf(notaId) == recipient, "Recipient isn't owner");
//     // //         } else {  // Invoice
//     // //             // assertTrue(nota.deposits(sender, dai) == 0, "Writer gained a deposit");
//     // //             assertTrue(nota.balanceOf(sender) == senderBalanceOf + 1, "Invoicer didn't get a nota");
//     // //             assertTrue(nota.balanceOf(recipient) == recipientBalanceOf, "Funder gained a nota");
//     // //             assertTrue(nota.ownerOf(notaId) == sender, "Invoicer isn't owner");
//     // //         }
//     // //         assertTrue(nota.totalSupply() == notaSupply + 1, "nota supply didn't increment");
//     // //         return notaId;
//     // //     }
//     // //     function testTransfernota(address caller,  uint256 amount, address recipient, uint256 duration, address to) public {
//     // //         vm.assume(amount <= dai.totalSupply());
//     // //         vm.assume(amount > 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(to != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, caller);
//     // //         uint256 notaId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         vm.prank(recipient);
//     // //         sstl.transfernota(notaId, to);
//     // //     }
//     // //     function testFailTransfernota(address caller, uint256 amount, address recipient, uint256 duration, address to) public {
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, caller);  // caller is writer
//     // //         uint256 notaId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         // Non-owner transfer
//     // //         vm.prank(caller);
//     // //         sstl.transfernota(notaId, to);
//     // //         // Transfer of non-existent nota
//     // //         vm.prank(caller);
//     // //         sstl.transfernota(notaId+1, to);
//     // //     }
//     // //     function testTransferInvoice(address caller, uint256 amount, address recipient, uint256 duration, address to) public {
//     // //         vm.assume(amount <= dai.totalSupply());
//     // //         vm.assume(amount > 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(to != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(!isContract(caller));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, caller);
//     // //         uint256 notaId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         vm.prank(caller);
//     // //         sstl.transfernota(notaId, to);
//     // //     }
//     // //     function testFailTransferInvoice(address caller, uint256 amount, address recipient, uint256 duration, address to) public {
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, caller);
//     // //         uint256 notaId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         // Non-owner transfer
//     // //         sstl.transfernota(notaId, to);
//     // //         vm.prank(recipient);
//     // //         sstl.transfernota(notaId, to);
//     // //         // Transfer to address(0)
//     // //         vm.prank(caller);
//     // //         sstl.transfernota(notaId, address(0));
//     // //         // Transfer to contract
//     // //         vm.prank(caller);
//     // //         sstl.transfernota(notaId, address(this));
//     // //         // Transfer of non-existent nota
//     // //         sstl.transfernota(notaId+1, to);
//     // //     }
//     // //     function transferHelper(uint256 notaId, address to, SelfSignTimeLock sstl) public {
//     // //         vm.prank(nota.ownerOf(notaId));
//     // //         sstl.transfernota(notaId, to);
//     // //     }
//     // //     function testFundInvoice(address caller, uint256 amount, address recipient, uint256 duration) public {  //
//     // //         vm.assume(amount <= dai.totalSupply());
//     // //         vm.assume(amount > 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(!isContract(caller));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, recipient);  // Recipient will be the funder
//     // //         uint256 notaId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         vm.prank(recipient);  // This can be anybody
//     // //         sstl.fundnota(notaId, amount);
//     // //         vm.expectRevert(bytes("Cant fund this amount"));
//     // //         sstl.fundnota(notaId, amount);
//     // //     }
//     // //     function testFailFundInvoice(address caller, uint256 amount, address recipient, uint256 duration, uint256 random) public {
//     // //         vm.assume(random != 0);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, recipient);  // Recipient will be the funder
//     // //         uint256 notaId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         vm.prank(recipient);
//     // //         sstl.fundnota(notaId, amount);
//     // //         vm.prank(caller);
//     // //         sstl.fundnota(notaId, amount);
//     // //         // invoice but not correct amount?
//     // //         depositHelper(amount, recipient);  // Recipient will be the funder
//     // //         uint256 notaId2 = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         vm.prank(recipient);
//     // //         sstl.fundnota(notaId2, amount+random);
//     // //         sstl.fundnota(notaId2, amount-random);
//     // //         vm.prank(caller);
//     // //         sstl.fundnota(notaId2, amount+random);
//     // //         sstl.fundnota(notaId2, amount-random);
//     // //     }
//     // //     function testCashnota(address caller, uint256 amount, address recipient, uint256 duration) public {
//     // //         vm.assume(amount <= dai.totalSupply());
//     // //         vm.assume(amount > 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         // Write nota from: caller, owner: recipient, to: recipient
//     // //         depositHelper(amount, caller);
//     // //         console.log("Supply", nota.totalSupply());
//     // //         uint256 notaId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         vm.startPrank(recipient);
//     // //         vm.warp(block.timestamp + duration);
//     // //         sstl.cashnota(notaId, nota.notaEscrowed(notaId));
//     // //         vm.stopPrank();
//     // //     }
//     // //     function testCashInvoice(address caller, uint256 amount, address recipient, uint256 duration) public {
//     // //         vm.assume(amount > 0  && amount <= dai.totalSupply());  //
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(!isContract(caller));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, recipient);
//     // //         uint256 notaId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         vm.prank(recipient);
//     // //         sstl.fundnota(notaId, amount);
//     // //         vm.startPrank(caller);
//     // //         vm.warp(block.timestamp + duration);
//     // //         sstl.cashnota(notaId, nota.notaEscrowed(notaId));
//     // //         vm.stopPrank();
//     // //     }
//     // //     function testFailCashnota(address caller, uint256 amount, address recipient, uint256 duration, uint256 random) public {
//     // //         vm.assume(amount != 0);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, recipient);
//     // //         uint256 notaId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         // Can't cash until its time
//     // //         vm.prank(recipient);
//     // //         sstl.cashnota(notaId, nota.notaEscrowed(notaId));
//     // //         // Can't cash unless owner
//     // //         vm.warp(block.timestamp + duration);
//     // //         sstl.cashnota(notaId, nota.notaEscrowed(notaId));
//     // //         // Can't cash different amount
//     // //         sstl.cashnota(notaId, nota.notaEscrowed(notaId)-random);
//     // //     }
//     // //     function testFailCashInvoice(address caller, uint256 amount, address recipient, uint256 duration, uint256 random) public {
//     // //         vm.assume(random != 0);
//     // //         vm.assume(amount != 0);
//     // //         vm.assume(amount > 0  && amount <= dai.totalSupply());
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(!isContract(caller));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         // if (!notaWriteCondition(caller, amount, recipient, duration) || amount != 0){
//     // //         //     require(false, "bad fuzzing");
//     // //         // }
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, recipient);
//     // //         uint256 notaId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         // Can't cash before inspection
//     // //         sstl.cashnota(notaId+1, nota.notaEscrowed(notaId));
//     // //         // Cant cash wrong nota
//     // //         vm.warp(block.timestamp + duration);
//     // //         sstl.cashnota(notaId+1, nota.notaEscrowed(notaId));  // You can cash an unfunded nota after inspectionPeriod
//     // //         // cant cash wrong amount
//     // //         sstl.cashnota(notaId, nota.notaEscrowed(notaId)+1);
//     // //     }
// }
// // // Need invoice encoded
// //         // Marketplace.Milestone memory milestone = Marketplace.Milestone({
// //         //     price: 10,
// //         //     workerFinished: false,
// //         //     clientReleased: false
// //         // });
// //         // Milestone[] memory milestones = new Milestone[](1);
// //         // milestones.push(milestone);
// //         // (uint256 startTime, Status workerStatus, Status clientStatus, Milestone[] memory milestones) = abi.encode(bytes(""), (uint256, Status, Status, Milestone[]));
// //         // bytes memory initData = abi.encode(milestones, (/*uint256, Status, Status, */Milestone[]));
