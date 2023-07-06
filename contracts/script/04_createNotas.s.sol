// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol"; 
import "../src/NotaRegistrar.sol";
import "forge-std/StdJson.sol"; 

// struct Tx1559 {
//     string[] arguments;
//     address contractAddress;
//     string contractName;
//     string functionSig;
//     bytes32 hash;
//     Tx1559Detail txDetail;
//     string opcode;
// }

// struct Tx1559Detail {
//     AccessList[] accessList;
//     bytes data;
//     address from;
//     uint256 gas;
//     uint256 nonce;
//     address to;
//     uint256 txType;
//     uint256 value;
// }
// contract CreateNotas is Script {
//     function testReadEIP1559Transactions() public {
//         string memory root = vm.projectRoot();
//         string memory path = string.concat(root, "/src/test/fixtures/broadcast.log.json");
//         Tx1559[] memory transactions = readTx1559s(path);
//         assertEq(transactions.length, 1);
//     }

//     function run() public {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);

//         string memory root = vm.projectRoot();
//         string memory path = string.concat(root, "/src/test/fixtures/broadcast.log.json");
//         string memory json = vm.readFile(path);
//         bytes memory transactionDetails = json.parseRaw(".transactions[0].tx");
//         RawTx1559Detail memory rawTxDetail = abi.decode(transactionDetails, (RawTx1559Detail));

//         vm.stopBroadcast();
//     }
// }