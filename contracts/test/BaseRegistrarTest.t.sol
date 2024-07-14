// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {IERC4906} from "../src/ERC4906.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {INotaRegistrar} from "../src/interfaces/INotaRegistrar.sol";
import {IRegistrarGov} from "../src/interfaces/IRegistrarGov.sol";
import {IHooks} from "../src/interfaces/IHooks.sol";
import "./mock/MockERC20.sol";
import "./mock/MockHook.sol";

abstract contract BaseRegistrarTest is Test {
    NotaRegistrar public REGISTRAR;
    MockHook public HOOK;
    MockERC20 public DAI;
    uint256 public immutable TOKENS_CREATED = 1_000_000_000_000e18;

    function setUp() public virtual {
        REGISTRAR = new NotaRegistrar(address(this)); 
        HOOK = new MockHook();
        DAI = new MockERC20("DAI", "DAI"); 
        DAI.mint(address(this), TOKENS_CREATED);

        vm.label(address(this), "TestingContract");
        vm.label(address(REGISTRAR), "NotaRegistrar");
        vm.label(address(DAI), "TestDai");
        vm.label(address(HOOK), "MockHook");
        vm.label(msg.sender, "MSG.SENDER");
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function safeFeeMult(
        uint256 fee,
        uint256 amount
    ) public pure returns (uint256) {
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
        
        uint256 hookFee = 0; // safeFeeMult(fees.writeBPS, totalTransfer);
        console.log("Hook Fee: ", hookFee);
        uint256 totalWithFees = totalTransfer + hookFee;
        console.log(totalTransfer, "-->", totalWithFees);
        return totalWithFees;
    }

    function _fundCallerApproveAddress(address caller, MockERC20 token, uint256 total, address toApprove) internal {
        uint256 initialBalance = token.balanceOf(caller);
        uint256 initialAllowance = token.allowance(caller, toApprove);

        token.transfer(caller, total);
        assertEq(token.balanceOf(caller), initialBalance + total, "Token Transfer Failed");

        vm.prank(caller);
        token.approve(toApprove, total);
        assertEq(token.allowance(caller, toApprove), initialAllowance + total, "Approval Failed");
    }

    function _tokenWhitelistToggle(address token, bool expectedState) internal {
        bool initialState = REGISTRAR.tokenWhitelisted(token);
        assertTrue(initialState != expectedState, "Redundant whitelist operation");

        REGISTRAR.whitelistToken(token, expectedState);
        assertEq(REGISTRAR.tokenWhitelisted(token), expectedState, "Whitelist state not updated correctly");
    }

    function _hookWhitelistToggle(IHooks hook, bool expectedState) internal {
        bool initialState = REGISTRAR.hookWhitelisted(hook);
        assertTrue(initialState != expectedState, "Redundant whitelist operation");

        REGISTRAR.whitelistHook(hook, expectedState);
        assertEq(REGISTRAR.hookWhitelisted(hook), expectedState, "Whitelist state not updated correctly");
    }

    function _URIFormat(string memory _string) internal pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;utf8,", _string));
    }

    function _registrarWriteAssumptions(address caller, uint256 escrow, uint256 instant, address owner) internal view {
        vm.assume(caller != address(0) && caller != owner && owner != address(0));
        vm.assume(owner != address(REGISTRAR) && caller != address(REGISTRAR) && caller != address(this) && owner != address(this));
        vm.assume((escrow + instant) <= TOKENS_CREATED);
    }

    function _registrarTransferAssumptions(address caller, address from, address to, uint256 notaId) internal view {
        vm.assume(caller != address(0) && to != address(0) && from != address(0));
        vm.assume(caller == from || REGISTRAR.isApprovedForAll(from, caller) || REGISTRAR.getApproved(notaId) == caller);
        vm.assume(from != to);
        vm.assume(to != address(REGISTRAR) && caller != address(REGISTRAR) && from != address(REGISTRAR) && caller != address(this));
    }

    // ---------------------- Main Operation Helpers ---------------------- //
    function _registrarWriteHelper(address caller, address currency, uint256 escrowed, uint256 instant, address owner, IHooks hook, bytes memory hookData) internal returns(uint256 notaId) {
        uint256 initialId = REGISTRAR.nextId();
        uint256 initialOwnerBalance = REGISTRAR.balanceOf(owner);
        uint256 initialCallerTokenBalance = IERC20(currency).balanceOf(caller);
        uint256 initialOwnerTokenBalance = IERC20(currency).balanceOf(owner);
        uint256 initialHookRevenue = REGISTRAR.hookRevenue(hook, currency);
        uint256 totalAmount = _calcTotalFees(hook, escrowed, instant);
        uint256 hookFee = totalAmount - (escrowed + instant);
        
        vm.expectEmit(true, true, true, true);
        emit INotaRegistrar.Written(caller, initialId, currency, escrowed, hook, instant, hookFee, hookData);
        
        vm.prank(caller);
        notaId = REGISTRAR.write(
            address(currency),
            escrowed,
            instant,
            owner,
            hook,
            hookData
        );
        
        assertEq(notaId, initialId, "Incorrect notaId returned");
        assertEq(REGISTRAR.nextId(), initialId + 1, "NextId didn't increment");
        assertEq(REGISTRAR.balanceOf(owner), initialOwnerBalance + 1, "Owner balance didn't increment");
        assertEq(REGISTRAR.ownerOf(notaId), owner, "`owner` isn't owner of nota");
        assertEq(REGISTRAR.hookRevenue(hook, currency), initialHookRevenue + hookFee, "Hook revenue didn't increase correctly");

        NotaRegistrar.Nota memory postNota = REGISTRAR.notaInfo(notaId);
        assertEq(postNota.currency, currency, "Incorrect currency");
        assertEq(postNota.escrowed, escrowed, "Incorrect escrowed amount");
        assertEq(address(postNota.hooks), address(hook), "Incorrect hook");

        assertEq(IERC20(currency).balanceOf(caller), initialCallerTokenBalance - totalAmount, "Caller currency balance didn't decrease correctly");
        assertEq(IERC20(currency).balanceOf(owner), initialOwnerTokenBalance + instant, "Owner currency balance didn't increase correctly");

        vm.expectEmit(true, true, true, true);
        emit IERC4906.MetadataUpdate(notaId);
    }

    function _registrarTransferHelper(address caller, address from, address to, uint256 notaId) internal {
        uint256 initialId = REGISTRAR.nextId();
        uint256 initialFromBalance = REGISTRAR.balanceOf(from);
        uint256 initialToBalance = REGISTRAR.balanceOf(to);
        assertEq(REGISTRAR.ownerOf(notaId), from, "Recipient should be the new owner of the token");
        NotaRegistrar.Nota memory preNota = REGISTRAR.notaInfo(notaId);
        
        uint256 initialHookRevenue = REGISTRAR.hookRevenue(preNota.hooks, address(preNota.currency));
        uint256 hookFee; // TODO

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(from, to, notaId);

        vm.expectEmit(true, true, true, true);
        emit INotaRegistrar.Transferred(caller, notaId, hookFee, "");
        
        vm.expectEmit(true, true, true, true);
        emit IERC4906.MetadataUpdate(notaId);

        vm.prank(caller);
        REGISTRAR.transferFrom(from, to, notaId);

        assertEq(REGISTRAR.nextId(), initialId, "NextId should remain unchanged");
        assertEq(REGISTRAR.balanceOf(from), initialFromBalance - 1, "Sender's balance should decrease by 1");
        assertEq(REGISTRAR.balanceOf(to), initialToBalance + 1, "Recipient's balance should increase by 1");
        assertEq(REGISTRAR.ownerOf(notaId), to, "Recipient should be the new owner of the token");

        NotaRegistrar.Nota memory postNota = REGISTRAR.notaInfo(notaId);
        assertEq(postNota.escrowed, preNota.escrowed, "Escrowed amount should not change");
        assertEq(postNota.currency, preNota.currency, "Currency should not change");
        assertEq(address(postNota.hooks), address(preNota.hooks), "Hook should not change");
        assertEq(initialHookRevenue, REGISTRAR.hookRevenue(preNota.hooks, address(preNota.currency)) + hookFee, "Owner currency balance didn't decrease");
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

        vm.expectEmit(true, true, true, true);
        emit INotaRegistrar.Funded(caller, notaId, amount, instant, hookFee, hookData);
        
        vm.expectEmit(true, true, true, true);
        emit IERC4906.MetadataUpdate(notaId);

        vm.prank(caller);
        REGISTRAR.fund(notaId, amount, instant, hookData);

        assertEq(REGISTRAR.notaEscrowed(notaId), preNota.escrowed + amount, "Escrowed amount didn't increase correctly");
        assertEq(currency.balanceOf(caller), initialCallerTokenBalance - totalAmount, "Caller currency balance didn't decrease correctly");
        assertEq(currency.balanceOf(notaOwner), initialOwnerTokenBalance + instant, "Owner currency balance didn't increase correctly");
        assertEq(REGISTRAR.hookRevenue(preNota.hooks, address(currency)), initialHookRevenue + hookFee, "Hook revenue didn't increase correctly");
    }

    function _registrarCashHelper(address caller, uint256 notaId, uint256 amount, address to, bytes memory hookData) internal {
        NotaRegistrar.Nota memory preNota = REGISTRAR.notaInfo(notaId);
        address notaOwner = REGISTRAR.ownerOf(notaId);

        IERC20 currency = IERC20(preNota.currency);
        uint256 initialToTokenBalance = currency.balanceOf(to);
        uint256 initialHookRevenue = REGISTRAR.hookRevenue(preNota.hooks, address(currency));
        
        uint256 totalAmount = _calcTotalFees(preNota.hooks, amount, 0);
        uint256 hookFee = totalAmount - amount;

        vm.expectEmit(true, true, true, true);
        emit INotaRegistrar.Cashed(caller, notaId, to, amount, hookFee, hookData);
        
        vm.expectEmit(true, true, true, true);
        emit IERC4906.MetadataUpdate(notaId);

        vm.prank(caller);
        REGISTRAR.cash(notaId, amount, to, hookData);

        assertEq(notaOwner, REGISTRAR.ownerOf(notaId), "Owner should remain the same");
        assertEq(REGISTRAR.notaEscrowed(notaId), preNota.escrowed - amount, "Escrowed amount didn't decrease correctly");
        assertEq(currency.balanceOf(to), initialToTokenBalance + amount, "Recipient currency balance didn't increase correctly");
        assertEq(REGISTRAR.hookRevenue(preNota.hooks, address(currency)), initialHookRevenue + hookFee, "Hook revenue didn't increase correctly");
    }

    function _registrarApproveHelper(address caller, address to, uint256 notaId) internal {
        address initialApproval = REGISTRAR.getApproved(notaId);

        vm.prank(caller);
        REGISTRAR.approve(to, notaId);

        assertNotEq(REGISTRAR.getApproved(notaId), initialApproval);
        assertEq(REGISTRAR.getApproved(notaId), to, "Approval should change");
    }

    function _registrarBurnHelper(address caller, uint256 notaId) internal {
        NotaRegistrar.Nota memory preNota = REGISTRAR.notaInfo(notaId);
        address owner = REGISTRAR.ownerOf(notaId);
        address approved = REGISTRAR.getApproved(notaId);
        vm.assume(caller == owner || caller == approved);

        uint256 initialId = REGISTRAR.nextId();
        uint256 ownerBalance = REGISTRAR.balanceOf(owner);

        // vm.expectEmit(true, true, true, true);
        // emit INotaRegistrar.Burned(caller, notaId);

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(owner, address(0), notaId);

        vm.prank(caller);
        REGISTRAR.burn(notaId);

        assertEq(REGISTRAR.balanceOf(owner), ownerBalance - 1, "Sender's balance should decrease by 1");

        vm.expectRevert("ERC721: invalid token ID");
        assertEq(REGISTRAR.getApproved(notaId), address(0), "Approved address should be 0");

        vm.expectRevert("ERC721: invalid token ID");
        REGISTRAR.ownerOf(notaId);

        vm.expectRevert(INotaRegistrar.NonExistent.selector);
        REGISTRAR.notaInfo(notaId);

        assertEq(REGISTRAR.nextId(), initialId, "Next ID should remain unchanged");
        assertEq(REGISTRAR.hookRevenue(preNota.hooks, preNota.currency), preNota.escrowed, "Hook revenue should include burned escrowed amount");
    }
}