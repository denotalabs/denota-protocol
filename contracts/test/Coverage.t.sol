// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {NotaRegistrar} from "../src/NotaRegistrar.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {Coverage} from "../src/modules/Coverage.sol";
import {RegistrarTest} from "./Registrar.t.sol";


contract CoverageTest is Test, RegistrarTest {
    Coverage public COVERAGE;

    function setUp() public override {
        super.setUp();  // init registrar, tokens, and their labels
        
        REGISTRAR.whitelistToken(address(DAI), true, "DAI");

        COVERAGE = new Coverage(
            address(REGISTRAR),
            DataTypes.WTFCFees(0, 0, 0, 0),
            "ipfs://", 
            address(DAI),
            120 days,
            180 days,
            2_000
        );

        REGISTRAR.whitelistModule(
            address(COVERAGE),
            true,
            false,
            "Coverage"
        );
        vm.label(address(COVERAGE), "Coverage");
    }

    function testDeposit() public {

    }
    
    function testWithdraw() public {
        
    }

    function testWrite(
        address caller,
        uint256 coverageAmount,
        uint256 escrowed,
        uint256 instant,
        address coverageHolder,
        address owner
    ) public {
        _preWriteTokens(caller, DAI, escrowed, instant, COVERAGE);
        registrarWriteBefore(caller, coverageHolder);

        vm.prank(caller);
        uint256 cheqId = REGISTRAR.write(
            address(DAI),
            escrowed,
            instant,
            owner,
            address(COVERAGE),
            abi.encode(
                coverageHolder, // coverageHolder
                coverageAmount, // coverageAmount
                50 // riskScore
            )
        ); 

        registrarWriteAfter(
            cheqId,
            address(DAI),
            escrowed,
            owner,
            address(COVERAGE)
        );

        // INotaModule wrote correctly to it's storage
        string memory tokenURI = REGISTRAR.tokenURI(cheqId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }
}
