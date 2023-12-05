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
//     //     uint256 public immutable TOKENS_CREATED = 1_000_000_000_000e18;
//     //     function isContract(address _addr) public view returns (bool){
//     //         uint32 size;
//     //         assembly {size := extcodesize(_addr)}
//     //         return (size > 0);
//     //     }
//     //     function setUp() public {  // sets up the registrar and ERC20s
//     //         REGISTRAR = new NotaRegistrar(DataTypes.WTFCFees(0,0,0,0));  // ContractTest is the owner
//     //         dai = new TestERC20(TOKENS_CREATED, "DAI", "DAI");  // Sends ContractTest the dai
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
//     //         Marketplace market = new Marketplace(address(REGISTRAR), allTrueAddress, allTrueAddress, allTrueAddress, allTrueAddress, allTrueAddress, DataTypes.WTFCFees(0,0,0,0), "MyMarket");
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
//     //     function cheqWriteCondition(address caller, uint256 amount, address recipient/*, uint256 duration*/) public view returns(bool){
//     //         return amount <= TOKENS_CREATED &&   // Can't use more token than created
//     //                caller != recipient &&  // Don't self send
//     //                caller != address(0) &&  // Don't vm.prank from address(0)
//     //                recipient != address(0) &&   // Can't send to, or transact from, address(0)
//     //                !isContract(recipient);// &&  // Don't send tokens to non-ERC721Reciever contracts
//     //             //    duration < type(uint).max &&  // Causes overflow
//     //             //    (duration >> 2) + (block.timestamp >> 2) <= (type(uint).max >> 2) ; // Causes overflow
//     //     }
//     //     function testWriteNota(address caller, uint256 amount, address recipient) public {
//     //         vm.assume(cheqWriteCondition(caller, amount, recipient));
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
//     //         assertTrue(REGISTRAR.balanceOf(caller) == 0, "Caller already had a cheq");
//     //         assertTrue(REGISTRAR.balanceOf(recipient) == 0, "Recipient already had a cheq");
//     //         assertTrue(REGISTRAR.totalSupply() == 0, "Nota supply non-zero");
//     //         DataTypes.Nota memory cheq = DataTypes.Nota({
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
//     //         uint256 cheqId = REGISTRAR.write(cheq, initData, caller);
//     //         assertTrue(REGISTRAR.totalSupply() == 1, "Nota supply didn't increment");
//     //         assertTrue(REGISTRAR.ownerOf(cheqId) == caller, "Recipient isn't owner");
//     //         assertTrue(REGISTRAR.balanceOf(caller) == 1, "Sender got a cheq");
//     //         // assertTrue(REGISTRAR.balanceOf(recipient) == 1, "Recipient didnt get a cheq");
//     //         // NotaRegistrar wrote correctly to its storage
//     //         assertTrue(REGISTRAR.cheqDrawer(cheqId) == caller, "Incorrect drawer");
//     //         assertTrue(REGISTRAR.cheqRecipient(cheqId) == recipient, "Incorrect recipient");
//     //         assertTrue(REGISTRAR.cheqCurrency(cheqId) == address(dai), "Incorrect token");
//     //         assertTrue(REGISTRAR.cheqAmount(cheqId) == amount, "Incorrect amount");
//     //         assertTrue(REGISTRAR.cheqEscrowed(cheqId) == amount, "Incorrect escrow");
//     //         assertTrue(address(REGISTRAR.cheqModule(cheqId)) == address(market), "Incorrect module");
//     //         // INotaModule wrote correctly to it's storage
//     //         (
//     //             uint256 startTime,
//     //             uint256 currentMilestone,
//     //             uint256 totalMilestones,
//     //             Marketplace.Status workerStatus,
//     //             Marketplace.Status clientStatus,
//     //             bytes32 documentHash
//     //         ) = market.invoices(cheqId);
//     //         Marketplace.Milestone[] memory milestones = market.getMilestones(cheqId);
//     //         // console.log(startTime, currentMilestone, workerStatus, clientStatus);
//     //         console.log("TotalMilestones: ");
//     //         console.log(totalMilestones);
//     //         for (uint256 i = 0; i < milestones.length; i++) { console.log(milestones[i].price); }
//     //         // assertTrue(market.cheqInspectionPeriod(cheqId) == duration, "Incorrect expired");
//     //     }
//     // //     function testWriteInvoice(address caller, address recipient, uint256 duration, uint256 amount) public {
//     // //         vm.assume(amount != 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(duration < type(uint256).max);
//     // //         assertTrue(REGISTRAR.balanceOf(caller) == 0, "Caller already had a cheq");
//     // //         assertTrue(REGISTRAR.balanceOf(recipient) == 0);
//     // //         assertTrue(REGISTRAR.totalSupply() == 0, "Nota supply non-zero");
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         vm.prank(caller);
//     // //         uint256 cheqId = sstl.writeNota(dai, amount, 0, recipient, duration);
//     // //         assertTrue(REGISTRAR.deposits(caller, dai) == 0, "Writer gained a deposit");
//     // //         assertTrue(REGISTRAR.totalSupply() == 1, "Nota supply didn't increment");
//     // //         assertTrue(REGISTRAR.balanceOf(caller) == 1, "Invoicer didn't get a cheq");
//     // //         assertTrue(REGISTRAR.balanceOf(recipient) == 0, "Recipient gained a cheq");
//     // //         assertTrue(REGISTRAR.ownerOf(cheqId) == caller, "Invoicer isn't owner");
//     // //         // INotaModule wrote correctly to NotaRegistrar storage
//     // //         assertTrue(REGISTRAR.cheqAmount(cheqId) == amount, "Incorrect amount");
//     // //         assertTrue(REGISTRAR.cheqToken(cheqId) == dai, "Incorrect token");
//     // //         assertTrue(REGISTRAR.cheqDrawer(cheqId) == caller, "Incorrect drawer");
//     // //         assertTrue(REGISTRAR.cheqRecipient(cheqId) == recipient, "Incorrect recipient");
//     // //         assertTrue(address(cheq.cheqModule(cheqId)) == address(sstl), "Incorrect module");
//     // //         // INotaModule wrote correctly to it's storage
//     // //         assertTrue(sstl.cheqFunder(cheqId) == recipient, "Nota reciever is same as on cheq");
//     // //         assertTrue(sstl.cheqReceiver(cheqId) == caller, "Nota reciever is same as on SSTL");
//     // //         assertTrue(sstl.cheqCreated(cheqId) == block.timestamp, "Nota created not at block.timestamp");
//     // //         assertTrue(sstl.cheqInspectionPeriod(cheqId) == duration, "Expired");
//     // //     }
//     // //     function testFailWriteNota(address caller, uint256 amount, address recipient, uint256 duration) public {
//     // //         vm.assume(amount <= dai.totalSupply());
//     // //         vm.assume(amount > 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         // Can't write cheq without a deposit on crx
//     // //         vm.prank(caller);
//     // //         sstl.writeNota(dai, amount, amount, recipient, duration);
//     // //         // Can't write cheques with insufficient balance
//     // //         depositHelper(amount, caller);
//     // //         sstl.writeNota(dai, amount, amount + 1, recipient, duration);  // Not enough escrow and amount!=escrow && escrow>0
//     // //         sstl.writeNota(dai, amount + 1, amount + 1, recipient, duration);  // Not enough escrow
//     // //         // Can't write directly from cheq
//     // //         vm.prank(caller);
//     // //         cheq.write(caller, caller, recipient, dai, amount, amount, recipient);
//     // //         // Can't write a 0 amount cheq??
//     // //         vm.prank(caller);
//     // //         sstl.writeNota(dai, 0, amount, recipient, duration);
//     // //         // Can't write a cheq with a higher escrow than amount??
//     // //         vm.prank(caller);
//     // //         sstl.writeNota(dai, amount, amount + 1, recipient, duration);
//     // //     }
//     // //     function helperNotaInfo(uint256 cheqId, uint256 amount, address sender, address recipient, SelfSignTimeLock sstl, uint256 duration) public {
//     // //         // INotaModule wrote correctly to NotaRegistrar storage
//     // //         assertTrue(cheq.cheqAmount(cheqId) == amount, "Incorrect amount");
//     // //         assertTrue(cheq.cheqToken(cheqId) == dai, "Incorrect token");
//     // //         assertTrue(cheq.cheqDrawer(cheqId) == sender, "Incorrect drawer");
//     // //         assertTrue(cheq.cheqRecipient(cheqId) == recipient, "Incorrect recipient");
//     // //         assertTrue(address(cheq.cheqModule(cheqId)) == address(sstl), "Incorrect module");
//     // //         // INotaModule wrote correctly to it's storage
//     // //         if (sstl.cheqFunder(cheqId) == sender){  // Nota
//     // //             assertTrue(cheq.cheqEscrowed(cheqId) == amount, "Incorrect escrowed amount");
//     // //             assertTrue(sstl.cheqFunder(cheqId) == cheq.cheqDrawer(cheqId), "Nota funder is not the sender");
//     // //             assertTrue(sstl.cheqReceiver(cheqId) == recipient, "Nota reciever is not recipient");
//     // //         } else {  // Invoice
//     // //             assertTrue(cheq.cheqEscrowed(cheqId) == 0, "Incorrect escrowed amount");
//     // //             assertTrue(sstl.cheqFunder(cheqId) == cheq.cheqRecipient(cheqId), "Nota reciever is same as on cheq");
//     // //             assertTrue(sstl.cheqReceiver(cheqId) == cheq.cheqDrawer(cheqId), "Nota reciever is same as on SSTL");
//     // //         }
//     // //         assertTrue(sstl.cheqCreated(cheqId) == block.timestamp, "Nota created not at block.timestamp");
//     // //         assertTrue(sstl.cheqInspectionPeriod(cheqId) == duration, "Expired");
//     // //     }
//     // //     function writeHelper(address sender, uint256 amount, uint256 escrow, address recipient, uint256 duration, SelfSignTimeLock sstl) public returns(uint256){
//     // //         uint256 senderBalanceOf = cheq.balanceOf(sender);
//     // //         uint256 recipientBalanceOf = cheq.balanceOf(recipient);
//     // //         uint256 cheqSupply = cheq.totalSupply();
//     // //         assertTrue(cheq.balanceOf(sender) == 0, "Caller already got a cheq");
//     // //         assertTrue(cheq.balanceOf(recipient) == 0);
//     // //         vm.prank(sender);
//     // //         uint256 cheqId = sstl.writeNota(dai, amount, escrow, recipient, duration);  // Change dai to arbitrary token
//     // //         helperNotaInfo(cheqId, amount, sender, recipient, sstl, duration);
//     // //         if (escrow == amount && amount != 0){ // Nota
//     // //             assertTrue(cheq.deposits(sender, dai) == 0, "Writer gained a deposit");
//     // //             assertTrue(cheq.balanceOf(sender) == senderBalanceOf, "Recipient gained a cheq");
//     // //             assertTrue(cheq.balanceOf(recipient) == recipientBalanceOf + 1, "Recipient didnt get a cheq");
//     // //             assertTrue(cheq.ownerOf(cheqId) == recipient, "Recipient isn't owner");
//     // //         } else {  // Invoice
//     // //             // assertTrue(cheq.deposits(sender, dai) == 0, "Writer gained a deposit");
//     // //             assertTrue(cheq.balanceOf(sender) == senderBalanceOf + 1, "Invoicer didn't get a cheq");
//     // //             assertTrue(cheq.balanceOf(recipient) == recipientBalanceOf, "Funder gained a cheq");
//     // //             assertTrue(cheq.ownerOf(cheqId) == sender, "Invoicer isn't owner");
//     // //         }
//     // //         assertTrue(cheq.totalSupply() == cheqSupply + 1, "Nota supply didn't increment");
//     // //         return cheqId;
//     // //     }
//     // //     function testTransferNota(address caller,  uint256 amount, address recipient, uint256 duration, address to) public {
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
//     // //         uint256 cheqId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         vm.prank(recipient);
//     // //         sstl.transferNota(cheqId, to);
//     // //     }
//     // //     function testFailTransferNota(address caller, uint256 amount, address recipient, uint256 duration, address to) public {
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, caller);  // caller is writer
//     // //         uint256 cheqId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         // Non-owner transfer
//     // //         vm.prank(caller);
//     // //         sstl.transferNota(cheqId, to);
//     // //         // Transfer of non-existent cheq
//     // //         vm.prank(caller);
//     // //         sstl.transferNota(cheqId+1, to);
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
//     // //         uint256 cheqId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         vm.prank(caller);
//     // //         sstl.transferNota(cheqId, to);
//     // //     }
//     // //     function testFailTransferInvoice(address caller, uint256 amount, address recipient, uint256 duration, address to) public {
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, caller);
//     // //         uint256 cheqId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         // Non-owner transfer
//     // //         sstl.transferNota(cheqId, to);
//     // //         vm.prank(recipient);
//     // //         sstl.transferNota(cheqId, to);
//     // //         // Transfer to address(0)
//     // //         vm.prank(caller);
//     // //         sstl.transferNota(cheqId, address(0));
//     // //         // Transfer to contract
//     // //         vm.prank(caller);
//     // //         sstl.transferNota(cheqId, address(this));
//     // //         // Transfer of non-existent cheq
//     // //         sstl.transferNota(cheqId+1, to);
//     // //     }
//     // //     function transferHelper(uint256 cheqId, address to, SelfSignTimeLock sstl) public {
//     // //         vm.prank(cheq.ownerOf(cheqId));
//     // //         sstl.transferNota(cheqId, to);
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
//     // //         uint256 cheqId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         vm.prank(recipient);  // This can be anybody
//     // //         sstl.fundNota(cheqId, amount);
//     // //         vm.expectRevert(bytes("Cant fund this amount"));
//     // //         sstl.fundNota(cheqId, amount);
//     // //     }
//     // //     function testFailFundInvoice(address caller, uint256 amount, address recipient, uint256 duration, uint256 random) public {
//     // //         vm.assume(random != 0);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, recipient);  // Recipient will be the funder
//     // //         uint256 cheqId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         vm.prank(recipient);
//     // //         sstl.fundNota(cheqId, amount);
//     // //         vm.prank(caller);
//     // //         sstl.fundNota(cheqId, amount);
//     // //         // invoice but not correct amount?
//     // //         depositHelper(amount, recipient);  // Recipient will be the funder
//     // //         uint256 cheqId2 = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         vm.prank(recipient);
//     // //         sstl.fundNota(cheqId2, amount+random);
//     // //         sstl.fundNota(cheqId2, amount-random);
//     // //         vm.prank(caller);
//     // //         sstl.fundNota(cheqId2, amount+random);
//     // //         sstl.fundNota(cheqId2, amount-random);
//     // //     }
//     // //     function testCashNota(address caller, uint256 amount, address recipient, uint256 duration) public {
//     // //         vm.assume(amount <= dai.totalSupply());
//     // //         vm.assume(amount > 0);
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(caller != address(0));
//     // //         vm.assume(recipient != address(0));
//     // //         vm.assume(!isContract(recipient));
//     // //         vm.assume(caller != recipient);
//     // //         vm.assume(duration < type(uint256).max);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         // Write cheq from: caller, owner: recipient, to: recipient
//     // //         depositHelper(amount, caller);
//     // //         console.log("Supply", cheq.totalSupply());
//     // //         uint256 cheqId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         vm.startPrank(recipient);
//     // //         vm.warp(block.timestamp + duration);
//     // //         sstl.cashNota(cheqId, cheq.cheqEscrowed(cheqId));
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
//     // //         uint256 cheqId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         vm.prank(recipient);
//     // //         sstl.fundNota(cheqId, amount);
//     // //         vm.startPrank(caller);
//     // //         vm.warp(block.timestamp + duration);
//     // //         sstl.cashNota(cheqId, cheq.cheqEscrowed(cheqId));
//     // //         vm.stopPrank();
//     // //     }
//     // //     function testFailCashNota(address caller, uint256 amount, address recipient, uint256 duration, uint256 random) public {
//     // //         vm.assume(amount != 0);
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, recipient);
//     // //         uint256 cheqId = writeHelper(caller, amount, amount, recipient, duration, sstl);
//     // //         // Can't cash until its time
//     // //         vm.prank(recipient);
//     // //         sstl.cashNota(cheqId, cheq.cheqEscrowed(cheqId));
//     // //         // Can't cash unless owner
//     // //         vm.warp(block.timestamp + duration);
//     // //         sstl.cashNota(cheqId, cheq.cheqEscrowed(cheqId));
//     // //         // Can't cash different amount
//     // //         sstl.cashNota(cheqId, cheq.cheqEscrowed(cheqId)-random);
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
//     // //         // if (!cheqWriteCondition(caller, amount, recipient, duration) || amount != 0){
//     // //         //     require(false, "bad fuzzing");
//     // //         // }
//     // //         SelfSignTimeLock sstl = setUpTimelock(caller);
//     // //         depositHelper(amount, recipient);
//     // //         uint256 cheqId = writeHelper(caller, amount, 0, recipient, duration, sstl);
//     // //         // Can't cash before inspection
//     // //         sstl.cashNota(cheqId+1, cheq.cheqEscrowed(cheqId));
//     // //         // Cant cash wrong cheq
//     // //         vm.warp(block.timestamp + duration);
//     // //         sstl.cashNota(cheqId+1, cheq.cheqEscrowed(cheqId));  // You can cash an unfunded cheq after inspectionPeriod
//     // //         // cant cash wrong amount
//     // //         sstl.cashNota(cheqId, cheq.cheqEscrowed(cheqId)+1);
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
