// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/access/ownable.sol";
import {Base64Encoding} from "./Base64Encoding.sol";

// // import {ModuleBase} from "./ModuleBase.sol";

// /**
//     Factory: Registrar <- Module
// */

// // contract Module is Ownable {
// //     mapping(address => bool) public allowList;

// //     function changeAllow(address _address, bool allowed) external onlyOwner {
// //         allowList[_address] = allowed;
// //     }

// //     function _processTransfer(
// //         address caller,
// //         address approved,
// //         address owner,
// //         address from,
// //         address to,
// //         uint256 cheqId,
// //         address currency,
// //         uint256 escrowed,
// //         uint256 createdAt,
// //         bytes calldata transferData
// //     ) internal virtual override returns (uint256) {
// //         address dappOperator = abi.decode(transferData, (address));
// //         // Add module logic here
// //         return takeReturnFee(currency, escrowed, dappOperator, 1);
// //     }

// //     function _processFund(
// //         address caller,
// //         address owner,
// //         uint256 amount,
// //         uint256 instant,
// //         uint256 cheqId,
// //         Cheq calldata cheq,
// //         bytes calldata fundData
// //     ) internal virtual override returns (uint256) {
// //         address dappOperator = abi.decode(fundData, (address));
// //         // Add module logic here
// //         return takeReturnFee(cheq.currency, amount + instant, dappOperator, 2);
// //     }

// //     function _processCash(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 amount,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata cashData
// //     ) internal virtual override returns (uint256) {
// //         address dappOperator = abi.decode(cashData, (address));
// //         // Add module logic here
// //         return takeReturnFee(cheq.currency, amount, dappOperator, 3);
// //     }

// //     function _processApproval(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes memory initData
// //     ) internal virtual override {
// //         // Add module logic here
// //     }

// //     function processTokenURI(
// //         uint256 tokenId
// //     ) internal view virtual override returns (string memory) {
// //         return string(abi.encodePacked(_URI, tokenId));
// //     }
// // }

// contract Registrar is ERC721, ICheqRegistrar, Base64Encoding {
//     using SafeERC20 for IERC20;
//     struct Cheq {
//         uint256 escrowed;
//         uint256 createdAt; // Set by caller and immutable
//         address currency; // Set by caller and immutable
//     }

//     mapping(uint256 => Cheq) private _cheqInfo;
//     uint256 private _totalSupply;

//     // error SendFailed();
//     error InvalidWrite(address, address);
//     error InsufficientValue(uint256, uint256);
//     error InsufficientEscrow(uint256, uint256);
//     event Written(
//         address indexed caller,
//         uint256 cheqId,
//         address indexed owner,
//         uint256 instant,
//         address currency,
//         uint256 escrowed,
//         uint256 createdAt,
//         uint256 moduleFee,
//         address indexed module,
//         bytes moduleData
//     );
//     // Not used
//     event Transferred(
//         uint256 indexed tokenId,
//         address indexed from,
//         address indexed to,
//         uint256 moduleFee,
//         uint256 timestamp
//     );
//     event Funded(
//         address indexed funder,
//         uint256 indexed cheqId,
//         uint256 amount,
//         uint256 instant,
//         bytes indexed fundData,
//         uint256 moduleFee,
//         uint256 timestamp
//     );
//     event Cashed(
//         address indexed casher,
//         uint256 indexed cheqId,
//         address to,
//         uint256 amount,
//         bytes indexed cashData,
//         uint256 moduleFee,
//         uint256 timestamp
//     );

//     modifier isMinted(uint256 cheqId) {
//         if (cheqId >= _totalSupply) revert NotMinted();
//         _;
//     }

//     constructor() ERC721("denota", "NOTA") {}

//     /*/////////////////////// WTFCAT ////////////////////////////*/
//     function write(
//         address currency,
//         uint256 escrowed,
//         uint256 instant,
//         address owner,
//         address module,
//         bytes calldata moduleWriteData
//     ) public payable returns (uint256) {
//         if (!validWrite(module, currency))
//             revert InvalidWrite(module, currency); // Module+token whitelist check
//         // Module hook (updates its storage, gets the fee)
//         uint256 moduleFee = _processWrite(
//             _msgSender(),
//             owner,
//             _totalSupply,
//             currency,
//             escrowed,
//             instant,
//             moduleWriteData
//         );

//         _transferTokens(escrowed, instant, currency, owner, moduleFee, module);

//         _mint(owner, _totalSupply);
//         _cheqInfo[_totalSupply] = Cheq(
//             escrowed,
//             block.timestamp,
//             currency,
//             module
//         );

//         emit Events.Written(
//             _msgSender(),
//             _totalSupply,
//             owner,
//             instant,
//             currency,
//             escrowed,
//             block.timestamp,
//             moduleFee,
//             module,
//             moduleWriteData
//         );
//         unchecked {
//             return _totalSupply++;
//         }
//     }

//     function transferFrom(
//         address from,
//         address to,
//         uint256 cheqId
//     ) public override(ERC721, ICheqRegistrar) isMinted(cheqId) {
//         _transferHookTakeFee(from, to, cheqId, abi.encode(""));
//         _transfer(from, to, cheqId);
//     }

//     function fund(
//         uint256 cheqId,
//         uint256 amount,
//         uint256 instant,
//         bytes calldata fundData
//     ) public payable isMinted(cheqId) {
//         DataTypes.Cheq storage cheq = _cheqInfo[cheqId]; // TODO module MUST check that token exists
//         address owner = ownerOf(cheqId); // Is used twice

//         // Module hook
//         uint256 moduleFee = processFund(
//             _msgSender(),
//             owner,
//             amount,
//             instant,
//             cheqId,
//             cheq,
//             fundData
//         );

//         // Fee taking and escrow
//         _transferTokens(
//             amount,
//             instant,
//             cheq.currency,
//             owner,
//             moduleFee,
//             cheq.module
//         );

//         _cheqInfo[cheqId].escrowed += amount; // Question: is this cheaper than testing if amount == 0?

//         emit Events.Funded(
//             _msgSender(),
//             cheqId,
//             amount,
//             instant,
//             fundData,
//             moduleFee,
//             block.timestamp
//         );
//     }

//     function cash(
//         uint256 cheqId,
//         uint256 amount,
//         address to,
//         bytes calldata cashData
//     ) public payable isMinted(cheqId) {
//         DataTypes.Cheq storage cheq = _cheqInfo[cheqId];

//         // Module Hook
//         uint256 moduleFee = processCash(
//             _msgSender(),
//             ownerOf(cheqId),
//             to,
//             amount,
//             cheqId,
//             cheq,
//             cashData
//         );

//         // Fee taking
//         uint256 totalAmount = amount + moduleFee;

//         // Un-escrowing
//         if (totalAmount > cheq.escrowed)
//             revert InsufficientEscrow(totalAmount, cheq.escrowed);
//         unchecked {
//             cheq.escrowed -= totalAmount;
//         } // Could this just underflow and revert anyway (save gas)?
//         if (cheq.currency == address(0)) {
//             (bool sent, ) = to.call{value: amount}("");
//             if (!sent) revert SendFailed();
//         } else {
//             IERC20(cheq.currency).safeTransfer(to, amount);
//         }
//         _moduleRevenue[cheq.module][cheq.currency] += moduleFee;

//         emit Events.Cashed(
//             _msgSender(),
//             cheqId,
//             to,
//             amount,
//             cashData,
//             moduleFee,
//             block.timestamp
//         );
//     }

//     function approve(
//         address to,
//         uint256 cheqId
//     ) public override(ERC721, ICheqRegistrar) isMinted(cheqId) {
//         if (to == _msgSender()) revert SelfApproval();

//         // Module hook
//         DataTypes.Cheq memory cheq = _cheqInfo[cheqId];
//         processApproval(_msgSender(), ownerOf(cheqId), to, cheqId, cheq, "");

//         // Approve
//         _approve(to, cheqId);
//     }

//     function tokenURI(
//         uint256 cheqId
//     ) public view override isMinted(cheqId) returns (string memory) {
//         string memory _tokenData = processTokenURI(cheqId);

//         return
//             buildMetadata(
//                 _tokenName[_cheqInfo[cheqId].currency],
//                 itoa(_cheqInfo[cheqId].escrowed),
//                 // itoa(_cheqInfo[_cheqId].createdAt),
//                 _moduleName[_cheqInfo[cheqId].module],
//                 _tokenData
//             );
//     }

//     /*///////////////////// BATCH FUNCTIONS ///////////////////////*/

//     function writeBatch(
//         address[] calldata currencies,
//         uint256[] calldata escrowedAmounts,
//         uint256[] calldata instantAmounts,
//         address[] calldata owners,
//         address[] calldata modules,
//         bytes[] calldata moduleWriteDataList
//     ) public payable returns (uint256[] memory cheqIds) {
//         uint256 numWrites = currencies.length;

//         require(
//             numWrites == escrowedAmounts.length &&
//                 numWrites == instantAmounts.length &&
//                 numWrites == owners.length &&
//                 numWrites == modules.length &&
//                 numWrites == moduleWriteDataList.length,
//             "Input arrays must have the same length"
//         );

//         for (uint256 i = 0; i < numWrites; i++) {
//             cheqIds[i] = write(
//                 currencies[i],
//                 escrowedAmounts[i],
//                 instantAmounts[i],
//                 owners[i],
//                 modules[i],
//                 moduleWriteDataList[i]
//             );
//         }
//     }

//     function transferFromBatch(
//         address[] calldata froms,
//         address[] calldata tos,
//         uint256[] calldata cheqIds
//     ) public {
//         uint256 numTransfers = froms.length;

//         require(
//             numTransfers == tos.length && numTransfers == cheqIds.length,
//             "Input arrays must have the same length"
//         );

//         for (uint256 i = 0; i < numTransfers; i++) {
//             transferFrom(froms[i], tos[i], cheqIds[i]);
//         }
//     }

//     function fundBatch(
//         uint256[] calldata cheqIds,
//         uint256[] calldata amounts,
//         uint256[] calldata instants,
//         bytes[] calldata fundDataList
//     ) public payable {
//         uint256 numFunds = cheqIds.length;

//         require(
//             numFunds == amounts.length &&
//                 numFunds == instants.length &&
//                 numFunds == fundDataList.length,
//             "Input arrays must have the same length"
//         );

//         for (uint256 i = 0; i < numFunds; i++) {
//             fund(cheqIds[i], amounts[i], instants[i], fundDataList[i]);
//         }
//     }

//     function cashBatch(
//         uint256[] calldata cheqIds,
//         uint256[] calldata amounts,
//         address[] calldata tos,
//         bytes[] calldata cashDataList
//     ) public payable {
//         uint256 numCash = cheqIds.length;

//         require(
//             numCash == amounts.length &&
//                 numCash == tos.length &&
//                 numCash == cashDataList.length,
//             "Input arrays must have the same length"
//         );

//         for (uint256 i = 0; i < numCash; i++) {
//             cash(cheqIds[i], amounts[i], tos[i], cashDataList[i]);
//         }
//     }

//     function approveBatch(
//         address[] memory tos,
//         uint256[] memory cheqIds
//     ) public {
//         uint256 numApprovals = tos.length;

//         require(
//             numApprovals == cheqIds.length,
//             "Input arrays must have the same length"
//         );

//         for (uint256 i = 0; i < numApprovals; i++) {
//             approve(tos[i], cheqIds[i]);
//         }
//     }

//     /*//////////////////////// HELPERS ///////////////////////////*/
//     function _transferTokens(
//         uint256 escrowed,
//         uint256 instant,
//         address currency,
//         address owner,
//         uint256 moduleFee,
//         address module
//     ) private {
//         uint256 toEscrow = escrowed + moduleFee; // Module forces user to escrow moduleFee, even when escrowed == 0
//         if (toEscrow + instant != 0) {
//             if (toEscrow > 0) {
//                 if (currency == address(0)) {
//                     if (msg.value < toEscrow)
//                         // User must send sufficient value ahead of time
//                         revert InsufficientValue(toEscrow, msg.value);
//                 } else {
//                     // User must approve sufficient value ahead of time
//                     IERC20(currency).safeTransferFrom(
//                         _msgSender(),
//                         address(this),
//                         toEscrow
//                     );
//                 }
//             }

//             if (instant > 0) {
//                 if (currency == address(0)) {
//                     if (msg.value != instant + toEscrow)
//                         // need to subtract toEscrow from msg.value
//                         revert InsufficientValue(instant + toEscrow, msg.value);
//                     (bool sent, ) = owner.call{value: instant}("");
//                     if (!sent) revert SendFailed();
//                 } else {
//                     IERC20(currency).safeTransferFrom(
//                         _msgSender(),
//                         owner,
//                         instant
//                     );
//                 }
//             }

//             _moduleRevenue[module][currency] += moduleFee;
//         }
//     }

//     function _transferHookTakeFee(
//         address from,
//         address to,
//         uint256 cheqId,
//         bytes memory moduleTransferData
//     ) internal {
//         if (moduleTransferData.length == 0)
//             moduleTransferData = abi.encode(owner());
//         address owner = ownerOf(cheqId); // require(from == owner,  "") ?
//         DataTypes.Cheq storage cheq = _cheqInfo[cheqId]; // Better to assign than to index?
//         // No approveOrOwner check, allow module to decide

//         // Module hook
//         uint256 moduleFee = processTransfer(
//             _msgSender(),
//             getApproved(cheqId),
//             owner,
//             from, // TODO Might not be needed
//             to,
//             cheqId,
//             cheq.currency,
//             cheq.escrowed,
//             cheq.createdAt,
//             moduleTransferData
//         );

//         // Fee taking and escrowing
//         if (cheq.escrowed > 0) {
//             // Can't take from 0 escrow
//             cheq.escrowed = cheq.escrowed - moduleFee;
//             _moduleRevenue[cheq.module][cheq.currency] += moduleFee;
//             emit Events.Transferred(
//                 cheqId,
//                 owner,
//                 to,
//                 moduleFee,
//                 block.timestamp
//             );
//         } else {
//             // Must be case since fee's can't be taken without an escrow to take from
//             emit Events.Transferred(cheqId, owner, to, 0, block.timestamp);
//         }
//     }

//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 cheqId,
//         bytes memory moduleTransferData
//     ) public override(ERC721, ICheqRegistrar) {
//         _transferHookTakeFee(from, to, cheqId, moduleTransferData);
//         _safeTransfer(from, to, cheqId, moduleTransferData);
//     }

//     /*///////////////////////// VIEW ////////////////////////////*/
//     function cheqInfo(
//         uint256 cheqId
//     ) public view returns (DataTypes.Cheq memory) {
//         if (cheqId >= _totalSupply) revert NotMinted();
//         return _cheqInfo[cheqId];
//     }

//     function cheqCurrency(uint256 cheqId) public view returns (address) {
//         if (cheqId >= _totalSupply) revert NotMinted();
//         return _cheqInfo[cheqId].currency;
//     }

//     function cheqEscrowed(uint256 cheqId) public view returns (uint256) {
//         if (cheqId >= _totalSupply) revert NotMinted();
//         return _cheqInfo[cheqId].escrowed;
//     }

//     function cheqModule(uint256 cheqId) public view returns (address) {
//         if (cheqId >= _totalSupply) revert NotMinted();
//         return _cheqInfo[cheqId].module;
//     }

//     function cheqCreatedAt(uint256 cheqId) public view returns (uint256) {
//         if (cheqId >= _totalSupply) revert NotMinted();
//         return _cheqInfo[cheqId].createdAt;
//     }

//     function totalSupply() public view returns (uint256) {
//         return _totalSupply;
//     }
// }

// contract Factory {
//     mapping(address => address) public deployerAddress;
//     address[] public admins;

//     constructor() {}

//     function deploy() external {
//         Registrar registrar = new AdminRegistrar();
//         deployerAddress[address(registrar)] = msg.sender;
//         admins.push(msg.sender);
//         registrar.transferOwnership(msg.sender);
//     }
// }

// /**
//     fee = (amount * fee) / BPS_MAX;
//     revenue[dappOperator][currency] += fee;
// */
