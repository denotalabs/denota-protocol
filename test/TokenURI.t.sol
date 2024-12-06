// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin/utils/Base64.sol";
import "openzeppelin/utils/Strings.sol";

import "./BaseRegistrarTest.t.sol";

contract TokenURITest is BaseRegistrarTest {
    address public caller = address(0xbeef);
    address public owner = address(0xdead);
    uint256 public notaId;
    uint256 escrowAmount = 1 ether;

    function setUp() public override {
        super.setUp();
        
        _fundCallerApproveAddress(caller, DAI, 100 ether, address(REGISTRAR));
        notaId = _registrarWriteHelper(caller, address(DAI), escrowAmount, 0, owner, HOOK, "");
    }

    function testTokenURI() public {
        string memory expectedTokenURI = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"attributes":[{"trait_type":"ERC20","value":"',
                            Strings.toHexString(address(DAI)),
                            '"},{"trait_type":"Amount","display_type":"number","value":',
                            Strings.toString(escrowAmount),
                            '},{"trait_type":"Hook Contract","value":"',
                            Strings.toHexString(address(HOOK)),
                            '"}',
                            "",
                            "]",
                            "",
                            "}"
                        )
                    )
                )
            )
        );
        
        assertEq(REGISTRAR.tokenURI(notaId), expectedTokenURI, "Token URI should match the expected URI");
    }

    function testQueryNonExistentTokenURI() public {
        uint256 nonExistentNotaId = 999;
        
        vm.expectRevert(INotaRegistrar.NonExistent.selector);
        REGISTRAR.tokenURI(nonExistentNotaId);
    }
}
