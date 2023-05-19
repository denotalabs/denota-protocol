// import "lib/foundry-zksync-era/script/Deployer.sol";

// // Diamond proxy addresses, last updated 24.03.2023
// address DIAMOND_PROXY_MAINNET = 0x32400084C286CF3E17e7B677ea9583e60a000324;
// address DIAMOND_PROXY_GOERLI = 0x1908e2BF4a88F91E4eF0DC72f02b8Ea36BEa2319;

// // Provide zkSync compiler version and address of the diamond proxy on L1
// Deployer deployer = new Deployer("1.3.7", DIAMOND_PROXY_MAINNET);

// // Provide path to contract, input params & salt
// // Returns deployment address on L2
// deployer.deployFromL1("src/Counter.sol", new bytes(0), bytes32(uint256(1337)));


// /// forge script script/Script.s.sol --ffi --broadcast --rpc-url L1_RPC_URL