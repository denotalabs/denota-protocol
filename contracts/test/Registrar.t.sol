// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mock/erc20.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import "./util/CheqRegistrarTest.sol";

// TODO add fail tests
contract RegistrarTest is CheqRegistrarTest {
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

    function setUp() public override {
        super.setUp();
        // sets up ERC20s
        dai = new TestERC20(tokensCreated, "DAI", "DAI"); // Sends ContractTest the dai
        usdc = new TestERC20(0, "USDC", "USDC");
        // REGISTRAR.whitelistToken(address(dai), true);
        // REGISTRAR.whitelistToken(address(usdc), true);

        vm.label(msg.sender, "Alice");
        vm.label(address(this), "TestingContract");
        vm.label(address(dai), "TestDai");
        vm.label(address(usdc), "TestUSDC");
        vm.label(address(REGISTRAR), "NotaRegistrarContract");
    }

    // function whitelist(address module, string calldata moduleName) public {
    //     // Whitelists tokens, rules, modules
    //     // REGISTRAR.whitelistRule(rule, true);
    //     REGISTRAR.whitelistModule(module, false, true, moduleName); // Whitelist bytecode
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
    // }

    /*//////////////////////////////////////////////////////////////
                            MODULE TESTS
    //////////////////////////////////////////////////////////////*/
    function calcFee(
        uint256 fee,
        uint256 amount
    ) public pure returns (uint256) {
        return (amount * fee) / 10_000;
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
        address currency,
        uint256 escrowed,
        address owner,
        address module
    ) public {
        assertTrue(
            REGISTRAR.totalSupply() == 1,
            "nota supply didn't increment"
        );

        assertTrue(
            REGISTRAR.balanceOf(owner) == 1,
            "Owner balance didn't increment"
        );

        assertTrue(
            REGISTRAR.ownerOf(notaId) == owner,
            "`owner` isn't owner of nota"
        );

        assertTrue(
            REGISTRAR.notaCurrency(notaId) == currency,
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
}

// // Whitelist module
// ReversibleRelease reversibleRelease = new ReversibleRelease(
//     address(REGISTRAR),
//     DataTypes.WTFCFees(0, 0, 0, 0),
//     "ipfs://"
// );
// address reversibleReleaseAddress = address(reversibleRelease);
// (bool addressWhitelisted, bool bytecodeWhitelisted) = REGISTRAR
//     .moduleWhitelisted(reversibleReleaseAddress);
// assertFalse(
//     addressWhitelisted || bytecodeWhitelisted,
//     "Unauthorized whitelist"
// );
// REGISTRAR.whitelistModule(reversibleReleaseAddress, true, false); // whitelist bytecode, not address
// (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(
//     reversibleReleaseAddress
// );
// assertTrue(
//     addressWhitelisted || bytecodeWhitelisted,
//     "Whitelisting failed"
// );
// REGISTRAR.whitelistModule(reversibleReleaseAddress, false, false);
// (addressWhitelisted, bytecodeWhitelisted) = REGISTRAR.moduleWhitelisted(
//     reversibleReleaseAddress
// );
// assertFalse(
//     addressWhitelisted || bytecodeWhitelisted,
//     "Un-whitelisting failed"
// );
