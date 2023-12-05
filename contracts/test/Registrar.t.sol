// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mock/erc20.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {INotaModule} from "../src/interfaces/INotaModule.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";

contract RegistrarTest is Test {
    NotaRegistrar public REGISTRAR;
    TestERC20 public DAI;
    TestERC20 public USDC;
    uint256 public immutable TOKENS_CREATED = 1_000_000_000_000e18;

    function setUp() public virtual {
        REGISTRAR = new NotaRegistrar(); 
        DAI = new TestERC20(TOKENS_CREATED, "DAI", "DAI"); 
        USDC = new TestERC20(0, "USDC", "USDC");  // TODO necessary?

        vm.label(msg.sender, "Alice");
        vm.label(address(this), "TestingContract");
        vm.label(address(DAI), "TestDai");
        vm.label(address(USDC), "TestUSDC");
        vm.label(address(REGISTRAR), "NotaRegistrarContract");
    }

    function isContract(address _addr) public view returns (bool) {
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

    function calcTotalFees(
        INotaModule module,
        uint256 escrowed,
        uint256 instant
    ) public view returns (uint256) {
        DataTypes.WTFCFees memory fees = module.getFees(address(0));
        uint256 totalTransfer = instant + escrowed;
        
        uint256 moduleFee = safeFeeMult(fees.writeBPS, totalTransfer);
        console.log("Module Fee: ", moduleFee);
        uint256 totalWithFees = totalTransfer + moduleFee;
        console.log(escrowed, "-->", totalWithFees);
        return totalWithFees;
    }

    function _fundCallerApproveRegistrar(address caller, TestERC20 token, uint256 escrowed, uint256 instant, INotaModule module) internal {
        // Calculate module's fees
        uint256 totalWithFees = calcTotalFees(
            module,
            escrowed,
            instant
        );
        
        // Give caller enough tokens
        token.transfer(caller, totalWithFees);
        // assertEq(token.balanceOf(caller), totalWithFees, "Token Transfer Failed");

        // Caller gives registrar approval
        vm.prank(caller);
        token.approve(address(REGISTRAR), totalWithFees); // Need to get the fee amounts beforehand
    }

    function registrarWriteBefore(address caller, address recipient) public {
        assertEq(
            REGISTRAR.balanceOf(caller), 0,
            "Caller already had a nota"
        );
        assertEq(
            REGISTRAR.balanceOf(recipient), 0,
            "Recipient already had a nota"
        );
        assertEq(REGISTRAR.totalSupply(), 0, "Nota supply non-zero");
    }
    
    function registrarWriteAfter(
        uint256 notaId,
        address currency,
        uint256 escrowed,
        address owner,
        address module
    ) public {
        assertEq(
            REGISTRAR.totalSupply(), 1,
            "Nota supply didn't increment"
        );

        assertEq(
            REGISTRAR.balanceOf(owner), 1,
            "Owner balance didn't increment"
        );

        assertEq(
            REGISTRAR.ownerOf(notaId), owner,
            "`owner` isn't owner of nota"
        );

        assertEq(
            REGISTRAR.cheqCurrency(notaId), currency,
            "Incorrect token"
        );

        assertEq(
            REGISTRAR.cheqEscrowed(notaId), escrowed,
            "Incorrect escrow"
        );

        assertEq(
            address(REGISTRAR.cheqModule(notaId)), module,
            "Incorrect module"
        );
    }

    function _writeHelper(        
        address caller,
        address currency,
        uint256 escrowed,
        uint256 instant,
        address owner,
        address module,
        bytes memory moduleWriteData) internal returns(uint256 notaId) {

        registrarWriteBefore(caller, owner);
        vm.prank(caller);
        notaId = REGISTRAR.write(
            currency,
            escrowed,
            instant,
            owner,
            module,
            moduleWriteData
        ); 
        registrarWriteAfter(
            notaId,
            currency,
            escrowed,
            owner,
            module
        );
    }

    function _registrarTokenWhitelistHelper(address token) internal {
        assertFalse(
            REGISTRAR.tokenWhitelisted(token),
            "Already Whitelisted"
        );

        REGISTRAR.whitelistToken(token, true, "DAI");
        
        assertTrue(
            REGISTRAR.tokenWhitelisted(token),
            "Whitelisting failed"
        );
    }

    function _registrarModuleWhitelistHelper(address module, bool bytecode, bool _address, string memory name) internal {
        assertTrue(bytecode != _address, "Can't do both");  // TODO make sure one is true

        (bool bytecodeWhitelist, bool addressWhitelist) = REGISTRAR.moduleWhitelisted(module);
        assertFalse(bytecodeWhitelist, "Already Whitelisted");
        assertFalse(addressWhitelist, "Already Whitelisted");

        REGISTRAR.whitelistModule(
            module,
            bytecode,
            _address,
            name
        );

        (bytecodeWhitelist, addressWhitelist) = REGISTRAR.moduleWhitelisted(module);
        if (bytecode){
            assertTrue(bytecodeWhitelist, "Bytecode Not Whitelisted");
        } else{
            assertTrue(addressWhitelist, "Address Not Whitelisted");
        }
    }

    function testWhitelistToken() public {
        // Add whitelist
         _registrarTokenWhitelistHelper(address(DAI));
        
        // Remove whitelist
        REGISTRAR.whitelistToken(address(DAI), false, "DAI");
        assertFalse(
            REGISTRAR.tokenWhitelisted(address(DAI)),
            "Un-whitelisting failed"
        );
    }

    function testWhitelistModule() public {
        // TODO
    }
}
