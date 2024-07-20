// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./BaseRegistrarTest.t.sol";

contract WhitelistTest is BaseRegistrarTest {
    function setUp() public override {
        super.setUp();
    }

    function testWhitelistToken() public {
        vm.expectEmit(true, true, true, true, address(REGISTRAR));
        emit IRegistrarGov.TokenWhitelisted(address(this), address(DAI), true);

        IRegistrarGov(REGISTRAR).whitelistToken(address(DAI), true);

        assertTrue(IRegistrarGov(REGISTRAR).tokenWhitelisted(address(DAI)));
    }

    function testFailWhitelistToken(address caller) public {
        vm.assume(caller != address(this));

        vm.prank(caller);
        IRegistrarGov(REGISTRAR).whitelistToken(address(DAI), true);
    }

    function testWhitelistHook() public {
        vm.expectEmit(true, true, true, true, address(REGISTRAR));
        emit IRegistrarGov.HookWhitelisted(address(this), IHooks(HOOK), true);

        IRegistrarGov(REGISTRAR).whitelistHook(IHooks(address(HOOK)), true);

        assertTrue(IRegistrarGov(REGISTRAR).hookWhitelisted(IHooks(HOOK)));
    }

    function testFailWhitelistHook(address caller) public {
        vm.assume(caller != address(this));

        vm.prank(caller);
        IRegistrarGov(REGISTRAR).whitelistToken(address(DAI), true);
    }

    function testValidWrite() public {
        IRegistrarGov(REGISTRAR).whitelistHook(IHooks(address(HOOK)), true);

        IRegistrarGov(REGISTRAR).whitelistToken(address(DAI), true);

        assertTrue(IRegistrarGov(REGISTRAR).validWrite(IHooks(address(HOOK)), address(DAI)));
    }

    function testFailValidWrite() public {
        require(IRegistrarGov(REGISTRAR).validWrite(IHooks(address(HOOK)), address(DAI)), "Invalid write");
    }
} 
