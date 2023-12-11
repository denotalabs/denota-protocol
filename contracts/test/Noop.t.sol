// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
// import {DataTypes} from "../src/libraries/DataTypes.sol";
import {Noop} from "../src/modules/Noop.sol";
import {RegistrarTest} from "./Registrar.t.sol";

contract NoopTest is Test, RegistrarTest {
    Noop public NOOP;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels   
        NOOP = new Noop(address(REGISTRAR));
        vm.label(address(NOOP), "Noop");
    }

    function _writeHelper(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) internal returns (uint256){
        uint256 notaId = _registrarWriteHelper(
            caller, 
            address(DAI), // currency
            escrowed, 
            instant,
            owner, 
            NOOP, // module
            "" // moduleData
        );
        return notaId;
    }

    function _writeNoopAssumptions(
        address caller,
        uint256 escrow,
        uint256 instant,
        address owner
    ) internal {
        vm.assume(caller != address(0) && caller != owner && owner != address(0));
        vm.assume((escrow/2 + instant/2) < TOKENS_CREATED / 2);

        vm.label(caller, "Caller");
        vm.label(owner, "Nota Owner");
    }

    function _setupThenWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) internal returns(uint256 notaId){
        _writeNoopAssumptions(caller, escrowed, instant, owner);

        _registrarModuleWhitelistHelper(NOOP, true);
        _registrarTokenWhitelistHelper(address(DAI));

        _tokenFundAddressApproveAddress(caller, DAI, escrowed, instant, NOOP, address(REGISTRAR));
        notaId = _writeHelper(caller, escrowed, instant, owner);
    }

    function testWrite(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        _setupThenWrite(caller, escrowed, instant, owner);
    }

    function testTransfer(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner, 
        address to
    ) public {
        vm.assume(owner != address(0) && to != address(0));  // Doesn't allow transfer to the zero address
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);
        REGISTRAR.transferFrom(owner, to, notaId); // TODO need to try from non owner address
    }

    function testFund(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        vm.assume((escrowed/2 + instant/2) < TOKENS_CREATED / 4);
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);
        _tokenFundAddressApproveAddress(caller, DAI, escrowed, instant, NOOP, address(REGISTRAR));

        vm.prank(caller);
        REGISTRAR.fund(notaId, escrowed, instant, abi.encode(""));
    }

    function testCash(
        address caller,
        uint256 escrowed,
        uint256 instant,
        address owner
    ) public {
        uint256 notaId = _setupThenWrite(caller, escrowed, instant, owner);
        REGISTRAR.cash(notaId, escrowed, caller, abi.encode(""));
    }

}