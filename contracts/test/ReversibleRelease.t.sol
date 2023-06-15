// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {ReverseRelease} from "../src/ReverseRelease.sol";
import {ReverseReleaseFactory} from "../src/ReverseRelease.sol";

/**
@custom:alex What else should be tested?
TODO test deploying multiple instances with same msg.sender
TODO use Uniswap create2 code
TODO URI not porking
 */
contract ReverseReleaseTest is Test {
    ReverseReleaseFactory public FACTORY;
    ReverseRelease public INSTANCE;

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
        FACTORY = new ReverseReleaseFactory(); // ContractTest is the owner
        address reverseReleaseAddress = FACTORY.deploy(); // Reverser is set as address(this)
        INSTANCE = ReverseRelease(reverseReleaseAddress);

        dai = new TestERC20(tokensCreated, "DAI", "DAI"); // Sends ContractTest the dai
        usdc = new TestERC20(0, "USDC", "USDC");

        vm.label(msg.sender, "Alice");
        vm.label(address(this), "TestContract");
        vm.label(address(FACTORY), "FACTORY");
        vm.label(address(INSTANCE), "INSTANCE");
    }

    // /*//////////////////////////////////////////////////////////////
    //                       WRAPPER TESTS
    // //////////////////////////////////////////////////////////////*/
    function writeConditions(
        address caller,
        address owner
    ) public view returns (bool) {
        return (caller != address(0) &&
            owner != address(0) &&
            caller != owner &&
            !isContract(caller) && // QUESTION: should this be allowed??? TODO BUG
            !isContract(owner)); // Don't send cheqs to non-ERC721Reciever contracts
    }

    function registrarWriteBefore(address caller, address recipient) public {
        assertTrue(
            INSTANCE.balanceOf(caller) == 0,
            "Caller already had a cheq"
        );
        assertTrue(
            INSTANCE.balanceOf(recipient) == 0,
            "Recipient already had a cheq"
        );
        assertTrue(INSTANCE.totalSupply() == 0, "Cheq supply non-zero");
    }

    function registrarWriteAfter(uint256 notaId, address owner) public {
        assertTrue(INSTANCE.totalSupply() == 1, "Cheq supply didn't increment");
        assertTrue(
            INSTANCE.ownerOf(notaId) == owner,
            "`owner` isn't owner of cheq"
        );
        assertTrue(
            INSTANCE.balanceOf(owner) == 1,
            "Owner balance didn't increment"
        );
    }

    function writeHelper(
        address caller,
        address owner,
        uint256 amount
    ) public returns (uint256) {
        vm.assume((amount < tokensCreated) && (amount > 0));
        vm.assume(writeConditions(caller, owner));

        registrarWriteBefore(caller, owner);

        vm.prank(address(this));
        dai.transfer(caller, amount);
        assertTrue(dai.balanceOf(caller) == amount, "Transfer failed");

        vm.prank(caller);
        dai.approve(address(INSTANCE), amount);
        vm.prank(caller);
        uint256 notaId = INSTANCE.write(address(dai), amount, owner);
        registrarWriteAfter(notaId, owner);
        assertTrue(
            dai.balanceOf(caller) == 0,
            "Caller escrow decrement failed"
        );
        assertTrue(
            dai.balanceOf(address(INSTANCE)) == amount,
            "Wrapper escrow increment failed"
        );
        return notaId;
    }

    function cashHelper(address caller, address owner, uint256 amount) public {
        //
    }

    function testWrite(address caller, address owner, uint256 amount) public {
        // TODO check that the sender's ASSET balance decrements
        vm.assume((amount < tokensCreated) && (amount > 0));
        vm.assume(writeConditions(caller, owner));

        registrarWriteBefore(caller, owner);

        vm.prank(address(this));
        dai.transfer(caller, amount);

        vm.prank(caller);
        dai.approve(address(INSTANCE), amount);
        vm.prank(caller);
        uint256 notaId = INSTANCE.write(address(dai), amount, owner);
        registrarWriteAfter(notaId, owner);

        string memory tokenURI = INSTANCE.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    function testReverse(address caller, address owner, uint256 amount) public {
        uint256 notaId = writeHelper(caller, owner, amount);
        uint256 amountEscrowed = INSTANCE.notaEscrowed(notaId);
        address notaSender = INSTANCE.notaSender(notaId);

        // vm.prank(address(this));
        INSTANCE.cash(notaId, true);
        assertTrue(INSTANCE.notaCashed(notaId), "Nota didn't cash");

        assertTrue(dai.balanceOf(address(INSTANCE)) == 0, "Decrement failed");
        assertTrue(
            dai.balanceOf(notaSender) == amountEscrowed,
            "Increment failed"
        );
        string memory tokenURI = INSTANCE.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    function testRelease(address caller, address owner, uint256 amount) public {
        uint256 notaId = writeHelper(caller, owner, amount);
        uint256 amountEscrowed = INSTANCE.notaEscrowed(notaId);
        address notaSender = INSTANCE.notaSender(notaId);
        address notaOwner = INSTANCE.ownerOf(notaId);

        // vm.prank(address(this));
        assertTrue(dai.balanceOf(notaOwner) == 0, "Decrement failed");
        INSTANCE.cash(notaId, false);
        assertTrue(INSTANCE.notaCashed(notaId), "Nota didn't cash");

        assertTrue(dai.balanceOf(notaSender) == 0, "Failed");
        assertTrue(dai.balanceOf(address(INSTANCE)) == 0, "Decrement failed");
        assertTrue(
            dai.balanceOf(notaOwner) == amountEscrowed,
            "Increment failed"
        );
        string memory tokenURI = INSTANCE.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    function testTransfer(
        address caller,
        address owner,
        uint256 amount
    ) public {
        uint256 notaId = writeHelper(caller, owner, amount);

        vm.prank(owner);
        INSTANCE.transferFrom(owner, address(1), notaId);
        assertTrue(INSTANCE.ownerOf(notaId) == address(1), "Transfer failed");
    }
}
