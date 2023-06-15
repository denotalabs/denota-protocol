// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "./mock/erc20.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Metadata.sol";

contract MetadataTest is Test {
    MetadataOnlyFactory public FACTORY;
    MetadataOnly public INSTANCE;

    // TestERC20 public dai;
    // TestERC20 public usdc;
    // uint256 public immutable tokensCreated = 1_000_000_000_000e18;

    function isContract(address _addr) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setUp() public {
        FACTORY = new MetadataOnlyFactory(); // ContractTest is the owner
        string memory _baseImageURI = "ipfs://";
        string memory _baseDocHashURI = "ipfs://";
        address metadataAddress = FACTORY.deploy(
            _baseImageURI,
            _baseDocHashURI
        );
        INSTANCE = MetadataOnly(metadataAddress);
        // dai = new TestERC20(tokensCreated, "DAI", "DAI"); // Sends ContractTest the dai
        // usdc = new TestERC20(0, "USDC", "USDC");

        vm.label(msg.sender, "Alice");
        vm.label(address(this), "TestContract");
        vm.label(address(FACTORY), "FACTORY");
        vm.label(address(INSTANCE), "INSTANCE");
    }

    // /*//////////////////////////////////////////////////////////////
    //                         MODULE TESTS
    // //////////////////////////////////////////////////////////////*/
    // function calcFee(
    //     uint256 fee,
    //     uint256 amount
    // ) public pure returns (uint256) {
    //     return (amount * fee) / 10_000;
    // }

    function writeConditions(
        address caller,
        address owner
    ) public view returns (bool) {
        return (caller != address(0) &&
            owner != address(0) &&
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

    function testWrite(address caller, address owner) public {
        vm.assume(writeConditions(caller, owner));

        registrarWriteBefore(caller, owner);

        string
            memory docHashURI = "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv";
        string
            memory imageURI = "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv";
        vm.prank(caller);
        uint256 notaId = INSTANCE.write(owner, imageURI, docHashURI);
        registrarWriteAfter(notaId, owner);

        string memory tokenURI = INSTANCE.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    // function calcTotalFees(
    //     DirectPay directPay,
    //     uint256 escrowed,
    //     uint256 directAmount
    // ) public view returns (uint256) {
    //     DataTypes.WTFCFees memory fees = directPay.getFees(address(0));
    //     uint256 moduleFee = calcFee(fees.writeBPS, directAmount + escrowed);
    //     console.log("ModuleFee: ", moduleFee);
    //     uint256 totalWithFees = escrowed + directAmount + moduleFee;
    //     console.log(directAmount, "-->", totalWithFees);
    //     return totalWithFees;
    // }
}

contract InstantMetadataToTest is Test {
    InstantMetadataToFactory public FACTORY;
    InstantMetadataTo public INSTANCE;
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
        FACTORY = new InstantMetadataToFactory(); // ContractTest is the owner
        string memory _baseImageURI = "ipfs://";
        string memory _baseDocHashURI = "ipfs://";
        address _address = FACTORY.deploy(_baseImageURI, _baseDocHashURI);
        INSTANCE = InstantMetadataTo(_address);
        dai = new TestERC20(tokensCreated, "DAI", "DAI"); // Sends ContractTest the dai
        usdc = new TestERC20(tokensCreated, "USDC", "USDC");

        vm.label(msg.sender, "Alice");
        vm.label(address(dai), "DAI");
        vm.label(address(usdc), "USDC");
        vm.label(address(this), "TestContract");
        vm.label(address(FACTORY), "FACTORY");
        vm.label(address(INSTANCE), "InstantMETADATATO");
    }

    // /*//////////////////////////////////////////////////////////////
    //                         MODULE TESTS
    // //////////////////////////////////////////////////////////////*/
    // function calcFee(
    //     uint256 fee,
    //     uint256 amount
    // ) public pure returns (uint256) {
    //     return (amount * fee) / 10_000;
    // }

    function writeConditions(
        address caller,
        address owner
    ) public view returns (bool) {
        return (caller != address(0) &&
            owner != address(0) &&
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

    function testWritePayDAI(
        address caller,
        address owner,
        uint256 amount
    ) public {
        vm.assume(writeConditions(caller, owner) && amount <= tokensCreated);
        registrarWriteBefore(caller, owner);

        dai.transfer(caller, amount);
        vm.prank(caller);
        dai.approve(address(INSTANCE), amount);
        assertTrue(dai.balanceOf(caller) >= amount, "TransferFailed");

        string
            memory docHashURI = "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv";
        string
            memory imageURI = "QmbZzDcAbfnNqRCq4Ym4ygp1AEdNKN4vqgScUSzR2DZQcv";
        vm.prank(caller);
        uint256 notaId = INSTANCE.write(
            owner,
            address(dai),
            amount,
            imageURI,
            docHashURI
        );
        registrarWriteAfter(notaId, owner);

        string memory tokenURI = INSTANCE.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    function testWritePayUSDC(
        address caller,
        address owner,
        uint256 amount
    ) public {
        vm.assume(writeConditions(caller, owner) && amount <= tokensCreated);
        registrarWriteBefore(caller, owner);

        usdc.transfer(caller, amount);
        vm.prank(caller);
        usdc.approve(address(INSTANCE), amount);
        assertTrue(usdc.balanceOf(caller) >= amount, "TransferFailed");

        string memory docHashURI = "abc123";
        string memory imageURI = "abc123";
        vm.prank(caller);
        uint256 notaId = INSTANCE.write(
            owner,
            address(usdc),
            amount,
            imageURI,
            docHashURI
        );
        registrarWriteAfter(notaId, owner);

        string memory tokenURI = INSTANCE.tokenURI(notaId);
        console.log("TokenURI: ");
        console.log(tokenURI);
    }

    // function calcTotalFees(
    //     DirectPay directPay,
    //     uint256 escrowed,
    //     uint256 directAmount
    // ) public view returns (uint256) {
    //     DataTypes.WTFCFees memory fees = directPay.getFees(address(0));
    //     uint256 moduleFee = calcFee(fees.writeBPS, directAmount + escrowed);
    //     console.log("ModuleFee: ", moduleFee);
    //     uint256 totalWithFees = escrowed + directAmount + moduleFee;
    //     console.log(directAmount, "-->", totalWithFees);
    //     return totalWithFees;
    // }
}
