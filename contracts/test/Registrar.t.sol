// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin/utils/Base64.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {INotaModule} from "../src/interfaces/INotaModule.sol";
import {Nota} from "../src/libraries/DataTypes.sol";
import "./mock/erc20.sol";

// TODO ensure failure on 0 escrow but moduleFee (or should module handle that??)
// TODO test event emission
// TODO have WTFCA vm.assumptions in helpers (owner != address(0), from == owner, etc)
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
        INotaModule module,
        uint256 escrowed,
        uint256 instant
    ) internal view returns (uint256) {
        // WTFCFees memory fees = module.getFees(address(0));
        uint256 totalTransfer = instant + escrowed;
        
        uint256 moduleFee = 0; //safeFeeMult(fees.writeBPS, totalTransfer);
        console.log("Module Fee: ", moduleFee);
        uint256 totalWithFees = totalTransfer + moduleFee;
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
    function _registrarModuleWhitelistToggleHelper(INotaModule module, bool alreadyWhitelisted) internal {
        bool isWhitelisted = REGISTRAR.moduleWhitelisted(module);
        if (alreadyWhitelisted){
            assertTrue(isWhitelisted, "Not Whitelisted");

            REGISTRAR.whitelistModule(module, false);

            assertFalse(REGISTRAR.moduleWhitelisted(module), "Address Still Whitelisted");
        } else {
            assertFalse(isWhitelisted, "Already Whitelisted");

            REGISTRAR.whitelistModule(module, true);

            assertTrue(REGISTRAR.moduleWhitelisted(module), "Address Not Whitelisted");
        }
    }

    function testWhitelistModule(INotaModule module) public {
        // Add whitelist
        _registrarModuleWhitelistToggleHelper(module, false);
        // Remove whitelist
        _registrarModuleWhitelistToggleHelper(module, true);
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

/*---------------------------------- Can't test these without a module ------------------------------------*/

    function _registrarWriteAssumptions(
        address caller,
        uint256 escrow,
        uint256 instant,
        address owner
    ) internal {
        vm.assume(caller != address(0) && caller != owner && owner != address(0));
        vm.assume(owner != address(REGISTRAR) && caller != address(REGISTRAR) && caller != address(this));  // TODO
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
        INotaModule module,
        bytes memory moduleBytes
        ) internal returns(uint256 notaId) {
        uint256 initialTotalSupply = REGISTRAR.totalSupply();
        uint256 initialOwnerBalance = REGISTRAR.balanceOf(owner);
        uint256 initialCallerTokenBalance = IERC20(currency).balanceOf(caller);
        uint256 initialOwnerTokenBalance = IERC20(currency).balanceOf(owner);
        uint256 initialModuleRevenue = REGISTRAR.moduleRevenue(module, currency);
        uint256 totalAmount = _calcTotalFees(module, escrowed, instant);
        uint256 moduleFee = totalAmount - (escrowed + instant);
        
        // bytes4 selector = bytes4(keccak256("NotMinted()"));
        // vm.expectRevert(abi.encodeWithSelector(selector, 1, 2) ); // TODO not working (0x4d5e5fb3 != ), nor hardcoding (0x4d5e5fb3 != 0x4d5e5fb3)
        // REGISTRAR.notaInfo(initialTotalSupply);

        vm.prank(caller);
        notaId = REGISTRAR.write(
            address(currency),
            escrowed,
            instant,
            owner,
            module,
            moduleBytes
        ); 
        
        assertEq(REGISTRAR.totalSupply(), initialTotalSupply + 1, "Nota supply didn't increment");
        assertEq(REGISTRAR.balanceOf(owner), initialOwnerBalance + 1, "Owner balance didn't increment");
        assertEq(REGISTRAR.ownerOf(notaId), owner, "`owner` isn't owner of nota");
        assertEq(REGISTRAR.moduleRevenue(module, currency), initialModuleRevenue + moduleFee, "Module revenue didn't increase");

        Nota memory postNota = REGISTRAR.notaInfo(initialTotalSupply);
        assertEq(postNota.currency, currency, "Incorrect token");
        assertEq(postNota.escrowed, escrowed, "Incorrect escrow");
        assertEq(address(postNota.module), address(module), "Incorrect module");

        assertEq(IERC20(currency).balanceOf(caller), initialCallerTokenBalance - totalAmount, "Caller currency balance didn't decrease");
        assertEq(IERC20(currency).balanceOf(owner), initialOwnerTokenBalance + instant, "Owner currency balance didn't decrease");
        console.log(REGISTRAR.tokenURI(notaId));
    }

    function _registrarTransferHelper(address caller, address from, address to, uint256 notaId) internal {
        // Initial state
        uint256 initialTotalSupply = REGISTRAR.totalSupply();
        uint256 initialFromBalance = REGISTRAR.balanceOf(from);
        uint256 initialToBalance = REGISTRAR.balanceOf(to);
        assertEq(REGISTRAR.ownerOf(notaId), from, "Recipient should be the new owner of the token");

        vm.prank(caller);
        REGISTRAR.transferFrom(from, to, notaId);

        // Verify state transition
        assertEq(REGISTRAR.totalSupply(), initialTotalSupply, "Total supply should remain unchanged");
        assertEq(REGISTRAR.balanceOf(from), initialFromBalance - 1, "Sender's balance should decrease by 1");
        assertEq(REGISTRAR.balanceOf(to), initialToBalance + 1, "Recipient's balance should increase by 1");
        assertEq(REGISTRAR.ownerOf(notaId), to, "Recipient should be the new owner of the token");
    }

    function _registrarFundHelper(address caller, uint256 notaId, uint256 amount, uint256 instant, bytes memory moduleBytes) internal {
        Nota memory preNota = REGISTRAR.notaInfo(notaId);
        address notaOwner = REGISTRAR.ownerOf(notaId);
        
        IERC20 currency = IERC20(preNota.currency);
        uint256 initialCallerTokenBalance = currency.balanceOf(caller);
        uint256 initialOwnerTokenBalance = currency.balanceOf(notaOwner);
        uint256 initialModuleRevenue = REGISTRAR.moduleRevenue(preNota.module, address(currency));
        
        uint256 totalAmount = _calcTotalFees(preNota.module, amount, instant);
        uint256 moduleFee = totalAmount - (amount + instant);

        vm.prank(caller);
        REGISTRAR.fund(notaId, amount, instant, moduleBytes);

         assertEq(preNota.escrowed, REGISTRAR.notaEscrowed(notaId) - amount);
         assertEq(currency.balanceOf(caller), initialCallerTokenBalance - totalAmount, "Caller currency balance didn't decrease");
         assertEq(currency.balanceOf(notaOwner), initialOwnerTokenBalance + instant, "Owner currency balance didn't decrease");
         assertEq(initialModuleRevenue, REGISTRAR.moduleRevenue(preNota.module, address(currency)) + moduleFee, "Owner currency balance didn't decrease");
    }

    function _registrarCashHelper(address caller, uint256 notaId, uint256 amount, address to, bytes memory moduleBytes) internal {
        Nota memory preNota = REGISTRAR.notaInfo(notaId);
        address notaOwner = REGISTRAR.ownerOf(notaId);

        IERC20 currency = IERC20(preNota.currency);
        uint256 initialOwnerTokenBalance = currency.balanceOf(notaOwner);
        uint256 initialModuleRevenue = REGISTRAR.moduleRevenue(preNota.module, address(currency));
        
        uint256 totalAmount = _calcTotalFees(preNota.module, amount, 0);
        uint256 moduleFee = totalAmount - amount;

        vm.prank(caller);
        REGISTRAR.cash(notaId, amount, to, moduleBytes);

         assertEq(preNota.escrowed, REGISTRAR.notaEscrowed(notaId) + totalAmount, "Total amount didnt decrement properly");
         assertEq(currency.balanceOf(notaOwner), initialOwnerTokenBalance + amount, "Owner currency balance didn't increase");
         assertEq(initialModuleRevenue, REGISTRAR.moduleRevenue(preNota.module, address(currency)) + moduleFee, "Owner currency balance didn't decrease");
    }
}