// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./BaseRegistrarTest.t.sol";

contract ContractURITest is BaseRegistrarTest {
    function setUp() public override {
        super.setUp();
    }

    function testOnlyOwner(address caller) public {
        vm.assume(caller != address(this));

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(caller);
        IRegistrarGov(REGISTRAR).setContractURI("newURI");
    }

    function testSetContractURI() public {
        string memory initialContractURI = REGISTRAR.contractURI();
        assertEq(initialContractURI, _URIFormat(""), "Initial contract URI should be empty");
        
        string memory newContractURI = '"{"name":"Denota Protocol","description:"A token agreement protocol","image":"ipfs://QmZfdTBo6Pnr7qbWg4FSeSiGNHuhhmzPbHgY7n8XrZbQ2v","banner_image":"ipfs://QmRcLdCxQ8qwKhzWtZrxKt1oAyKvCMJLZV7vV5jUnBNzoq","external_link":"https://denota.xyz/","collaborators":["almaraz.eth","0xrafi.eth","pengu1689.eth"]}"';
        
        vm.expectEmit(true, true, true, true, address(REGISTRAR));
        emit IRegistrarGov.ContractURIUpdated();

        REGISTRAR.setContractURI(newContractURI);
        assertEq(REGISTRAR.contractURI(), _URIFormat(newContractURI), "Contract URI should be updated");
    }
}