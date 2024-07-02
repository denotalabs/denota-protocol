// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mock/erc20.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {INotaRegistrar} from "../src/interfaces/INotaRegistrar.sol";
import {IHooks} from "../src/interfaces/IHooks.sol";

// TODO ensure failure on 0 escrow but hookFee
// TODO test event emission
// TODO have WTFCA vm.assumptions in helpers (owner != address(0), from == owner, etc)
// Add invariant tests for registrar here (token transfers, etc)
contract RegistrarTest is Test {
    NotaRegistrar public REGISTRAR;
    TestERC20 public DAI;
    uint256 public immutable TOKENS_CREATED = 1_000_000_000_000e18;

    function setUp() public virtual {
        REGISTRAR = new NotaRegistrar(address(this)); 

        DAI = new TestERC20(TOKENS_CREATED, "DAI", "DAI"); 

        vm.label(msg.sender, "Alice");
        vm.label(address(this), "TestingContract");
        vm.label(address(DAI), "TestDai");
        vm.label(address(REGISTRAR), "NotaRegistrarContract");
    }

    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function safeFeeMult(
        uint256 fee,
        uint256 amount
    ) internal pure returns (uint256) {
        if (fee == 0) return 0;
        return (amount * fee) / 10_000;
    }

    function _calcTotalFees(
        IHooks hook,
        uint256 escrowed,
        uint256 instant
    ) internal view returns (uint256) {
        // WTFCFees memory fees = hook.getFees(address(0));
        uint256 totalTransfer = instant + escrowed;
        
        uint256 hookFee = 0; //safeFeeMult(fees.writeBPS, totalTransfer);
        console.log("Hook Fee: ", hookFee);
        uint256 totalWithFees = totalTransfer + hookFee;
        console.log(totalTransfer, "-->", totalWithFees);
        return totalWithFees;
    }

    function _tokenFundAddressApproveAddress(address caller, TestERC20 token, uint256 total, address toApprove) internal {
        uint256 initialBalance = token.balanceOf(caller);
        uint256 initialAllowance = token.allowance(caller, toApprove);

        token.transfer(caller, total);
        assertEq(token.balanceOf(caller), initialBalance + total, "Token Transfer Failed");

        vm.prank(caller);
        token.approve(toApprove, total);
        assertEq(token.allowance(caller, toApprove), initialAllowance + total);
    }

    function _registrarTokenWhitelistToggleHelper(address token, bool alreadyWhitelisted) internal {
        bool isWhitelisted = REGISTRAR.tokenWhitelisted(token);
        if (alreadyWhitelisted){ // from whitelisted to not
            assertTrue(isWhitelisted, "Not Whitelisted");

            REGISTRAR.whitelistToken(token, false);

            assertFalse(REGISTRAR.tokenWhitelisted(token), "Address Still Whitelisted");
        } else {  // from not whitelisted to whitelisted
            assertFalse(isWhitelisted, "Already Whitelisted");

            REGISTRAR.whitelistToken(token, true);

            assertTrue(REGISTRAR.tokenWhitelisted(token), "Address Not Whitelisted");
        }
    }

    function testWhitelistToken() public {
        // Add to whitelist
         _registrarTokenWhitelistToggleHelper(address(DAI), false); // false -> true
        // Remove from whitelist
        _registrarTokenWhitelistToggleHelper(address(DAI), true); // true -> false
    }
    function _registrarHookWhitelistToggleHelper(IHooks hook, bool alreadyWhitelisted) internal {
        bool isWhitelisted = REGISTRAR.hookWhitelisted(hook);
        if (alreadyWhitelisted){
            assertTrue(isWhitelisted, "Not Whitelisted");

            REGISTRAR.whitelistHook(hook, false);

            assertFalse(REGISTRAR.hookWhitelisted(hook), "Address Still Whitelisted");
        } else {
            assertFalse(isWhitelisted, "Already Whitelisted");

            REGISTRAR.whitelistHook(hook, true);

            assertTrue(REGISTRAR.hookWhitelisted(hook), "Address Not Whitelisted");
        }
    }

    function testWhitelistHook(IHooks hook) public {
        // Add whitelist
        _registrarHookWhitelistToggleHelper(hook, false);
        // Remove whitelist
        _registrarHookWhitelistToggleHelper(hook, true);
    }

    function _URIFormat(string memory _string) internal pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;utf8,", _string));
    }

    function testSetContractURI() public {
        string memory initialContractURI = REGISTRAR.contractURI();
        assertEq(initialContractURI, _URIFormat(""), "Initial contract URI should be empty");
        
        string memory newContractURI = '"{"name":"Denota Protocol","description:"A token agreement protocol","image":"ipfs://QmZfdTBo6Pnr7qbWg4FSeSiGNHuhhmzPbHgY7n8XrZbQ2v","banner_image":"ipfs://QmRcLdCxQ8qwKhzWtZrxKt1oAyKvCMJLZV7vV5jUnBNzoq","external_link":"https://denota.xyz/","collaborators":["almaraz.eth","0xrafi.eth","pengu1689.eth"]}"';
        
        vm.prank(address(this));
        REGISTRAR.setContractURI(newContractURI);
        assertEq(REGISTRAR.contractURI(), _URIFormat(newContractURI), "Contract URI should be updated");
    }

    // function testSetApprovalForAll() public {
    //     address owner = address(0x123);
    //     address operator = address(0x456);

    //     vm.prank(owner);
    //     REGISTRAR.setApprovalForAll(operator, true);

    //     assertTrue(REGISTRAR.isApprovedForAll(owner, operator));

    //     vm.prank(owner);
    //     REGISTRAR.setApprovalForAll(operator, false);

    //     assertFalse(REGISTRAR.isApprovedForAll(owner, operator));
    // }

    // function testRevokeApproval() public {
    //     address caller = address(0x123);
    //     uint256 escrowed = 1000;
    //     uint256 instant = 500;
    //     address owner = address(0x456);
    //     address approved = address(0x789);

    //     // uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner, "");

    //     vm.prank(owner);
    //     REGISTRAR.approve(approved, notaId);
    //     assertEq(REGISTRAR.getApproved(notaId), approved);

    //     vm.prank(owner);
    //     REGISTRAR.approve(address(0), notaId);
    //     assertEq(REGISTRAR.getApproved(notaId), address(0));
    // }

    // function testTransferFromApprovedOperator() public {
    //     address caller = address(0x123);
    //     uint256 escrowed = 1000;
    //     uint256 instant = 500;
    //     address owner = address(0x456);
    //     address operator = address(0x789);
    //     address recipient = address(0xabc);

    //     uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner, "");

    //     vm.prank(owner);
    //     REGISTRAR.setApprovalForAll(operator, true);

    //     vm.prank(operator);
    //     REGISTRAR.transferFrom(owner, recipient, notaId);

    //     assertEq(REGISTRAR.ownerOf(notaId), recipient);
    // }

/*---------------------------------- Can't test these without a hook ------------------------------------*/

    function _registrarWriteAssumptions(
        address caller,
        uint256 escrow,
        uint256 instant,
        address owner
    ) internal {
        vm.assume(caller != address(0) && caller != owner && owner != address(0));
        vm.assume(owner != address(REGISTRAR) && caller != address(REGISTRAR) && caller != address(this) && owner != address(this));  // TODO
        vm.assume((escrow/2 + instant/2) < TOKENS_CREATED / 2);

        vm.label(caller, "Writer");
        vm.label(owner, "Nota Owner");
    }

    function _registrarTransferAddressAssumptions(
        address caller,
        address owner,
        address to
    ) internal {
        vm.assume(caller != address(0) && to != address(0) && owner != address(0));  // No address(0)
        vm.assume(owner != to);  // No self-transfers
        vm.assume(to != address(REGISTRAR) && caller != address(REGISTRAR) && caller != address(this)  && owner != address(REGISTRAR));  // No special contracts

        vm.label(caller, "Transferer");
        vm.label(to, "New Nota Owner");
    }

    function _registrarTransferApprovedAssumptions(
        address caller,
        address owner,
        uint256 notaId
    ) internal view {
        vm.assume(caller == owner || REGISTRAR.isApprovedForAll(owner, caller) || REGISTRAR.getApproved(notaId) == caller); // No unauthorized transfers
    }

    function _registrarWriteHelper(        
        address caller,
        address currency,
        uint256 escrowed,
        uint256 instant,
        address owner,
        IHooks hook,
        bytes memory hookData
        ) internal returns(uint256 notaId) {
        uint256 initialId = REGISTRAR.nextId();
        uint256 initialOwnerBalance = REGISTRAR.balanceOf(owner);
        uint256 initialCallerTokenBalance = IERC20(currency).balanceOf(caller);
        uint256 initialOwnerTokenBalance = IERC20(currency).balanceOf(owner);
        uint256 initialHookRevenue = REGISTRAR.hookRevenue(hook, currency);
        uint256 totalAmount = _calcTotalFees(hook, escrowed, instant);
        uint256 hookFee = totalAmount - (escrowed + instant);
        
        // bytes4 selector = bytes4(keccak256("NotMinted()"));
        // vm.expectRevert(abi.encodeWithSelector(selector, 1, 2) ); // TODO not working (0x4d5e5fb3 != ), nor hardcoding (0x4d5e5fb3 != 0x4d5e5fb3)
        // REGISTRAR.notaInfo(initialId);

        vm.prank(caller);
        notaId = REGISTRAR.write(
            address(currency),
            escrowed,
            instant,
            owner,
            hook,
            hookData
        ); 
        
        assertEq(REGISTRAR.nextId(), initialId + 1, "NextId didn't increment");
        assertEq(REGISTRAR.balanceOf(owner), initialOwnerBalance + 1, "Owner balance didn't increment");
        assertEq(REGISTRAR.ownerOf(notaId), owner, "`owner` isn't owner of nota");
        assertEq(REGISTRAR.hookRevenue(hook, currency), initialHookRevenue + hookFee, "Hook revenue didn't increase");

        NotaRegistrar.Nota memory postNota = REGISTRAR.notaInfo(initialId);
        assertEq(postNota.currency, currency, "Incorrect token");
        assertEq(postNota.escrowed, escrowed, "Incorrect escrow");
        assertEq(address(postNota.hooks), address(hook), "Incorrect hook");

        assertEq(IERC20(currency).balanceOf(caller), initialCallerTokenBalance - totalAmount, "Caller currency balance didn't decrease");
        assertEq(IERC20(currency).balanceOf(owner), initialOwnerTokenBalance + instant, "Owner currency balance didn't decrease");
        console.log(REGISTRAR.tokenURI(notaId));
    }

    function _registrarTransferHelper(address caller, address from, address to, uint256 notaId) internal {
        // Initial state
        uint256 initialId = REGISTRAR.nextId();
        uint256 initialFromBalance = REGISTRAR.balanceOf(from);
        uint256 initialToBalance = REGISTRAR.balanceOf(to);
        assertEq(REGISTRAR.ownerOf(notaId), from, "Recipient should be the new owner of the token");

        vm.prank(caller);
        REGISTRAR.transferFrom(from, to, notaId);

        // Verify state transition
        assertEq(REGISTRAR.nextId(), initialId, "NextId should remain unchanged");
        assertEq(REGISTRAR.balanceOf(from), initialFromBalance - 1, "Sender's balance should decrease by 1");
        assertEq(REGISTRAR.balanceOf(to), initialToBalance + 1, "Recipient's balance should increase by 1");
        assertEq(REGISTRAR.ownerOf(notaId), to, "Recipient should be the new owner of the token");
    }

    function _registrarFundHelper(address caller, uint256 notaId, uint256 amount, uint256 instant, bytes memory hookData) internal {
        NotaRegistrar.Nota memory preNota = REGISTRAR.notaInfo(notaId);
        address notaOwner = REGISTRAR.ownerOf(notaId);
        
        IERC20 currency = IERC20(preNota.currency);
        uint256 initialCallerTokenBalance = currency.balanceOf(caller);
        uint256 initialOwnerTokenBalance = currency.balanceOf(notaOwner);
        uint256 initialHookRevenue = REGISTRAR.hookRevenue(preNota.hooks, address(currency));
        
        uint256 totalAmount = _calcTotalFees(preNota.hooks, amount, instant);
        uint256 hookFee = totalAmount - (amount + instant);

        vm.prank(caller);
        REGISTRAR.fund(notaId, amount, instant, hookData);

        assertEq(preNota.escrowed, REGISTRAR.notaEscrowed(notaId) - amount, "Escrowed amount didn't increment properly");
        assertEq(currency.balanceOf(caller), initialCallerTokenBalance - totalAmount, "Caller currency balance didn't decrease");
        assertEq(currency.balanceOf(notaOwner), initialOwnerTokenBalance + instant, "Owner currency balance didn't decrease");
        assertEq(initialHookRevenue, REGISTRAR.hookRevenue(preNota.hooks, address(currency)) + hookFee, "Owner currency balance didn't decrease");
    }

    function _registrarCashHelper(address caller, uint256 notaId, uint256 amount, address to, bytes memory hookData) internal {
        NotaRegistrar.Nota memory preNota = REGISTRAR.notaInfo(notaId);
        // address notaOwner = REGISTRAR.ownerOf(notaId);

        IERC20 currency = IERC20(preNota.currency);
        uint256 initialToTokenBalance = currency.balanceOf(to);
        uint256 initialHookRevenue = REGISTRAR.hookRevenue(preNota.hooks, address(currency));
        
        uint256 totalAmount = _calcTotalFees(preNota.hooks, amount, 0);
        uint256 hookFee = totalAmount - amount;

        vm.prank(caller);
        REGISTRAR.cash(notaId, amount, to, hookData);

         assertEq(preNota.escrowed, REGISTRAR.notaEscrowed(notaId) + totalAmount, "Total amount didnt decrement properly");
         assertEq(currency.balanceOf(to), initialToTokenBalance + amount, "Owner currency balance didn't increase");
         assertEq(initialHookRevenue, REGISTRAR.hookRevenue(preNota.hooks, address(currency)) + hookFee, "Owner currency balance didn't decrease");
    }

    // function _registrarApproveHelper(address caller, address to, uint256 notaId) internal {
    //     address initialApproval = REGISTRAR.getApproved(notaId);

    //     vm.prank(caller);
    //     REGISTRAR.approve(to, notaId);

    //     // Verify state transition
    //     assertNotEq(REGISTRAR.getApproved(notaId), initialApproval);
    //     assertEq(REGISTRAR.getApproved(notaId), to, "Approval should change");
    // }

    function _registrarBurnHelper(address caller, uint256 notaId) internal {
        // Initial state
        address owner = REGISTRAR.ownerOf(notaId);
        address approved = REGISTRAR.getApproved(notaId);
        vm.assume(caller == owner || caller == approved);

        uint256 ownerBalance = REGISTRAR.balanceOf(owner);
        uint256 initialId = REGISTRAR.nextId();
        REGISTRAR.notaInfo(notaId);

        vm.prank(caller);
        REGISTRAR.burn(notaId);

        // Verify state transition
        assertEq(REGISTRAR.balanceOf(owner), ownerBalance - 1, "Sender's balance should decrease by 1");

        vm.expectRevert("ERC721: invalid token ID");
        assertEq(REGISTRAR.getApproved(notaId), address(0), "Approved address should be 0");

        vm.expectRevert("ERC721: invalid token ID");
        REGISTRAR.ownerOf(notaId);

        vm.expectRevert(INotaRegistrar.NonExistent.selector);
        REGISTRAR.notaInfo(notaId);

        assertEq(REGISTRAR.nextId(), initialId, "Next ID should remain unchanged");
    }
}