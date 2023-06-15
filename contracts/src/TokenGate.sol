// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity ^0.8.16;
// import "openzeppelin/token/ERC721/ERC721.sol";
// import "openzeppelin/token/ERC20/IERC20.sol";
// import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
// import "openzeppelin/utils/Base64.sol";
// import {Base64Encoding} from "./Base64Encoding.sol";

// contract TokenGate is ERC721, Base64Encoding {
//     using SafeERC20 for IERC20;

//     struct Nota {
//         uint256 escrowed;
//         uint256 createdAt;
//         string docHash;
//         string imageURI;
//     }
//     address public tokenGate;
//     address public currency; // Does it make sense to separate by gate AND currency?
//     mapping(uint256 => Nota) private _cheqInfo;
//     uint256 private _totalSupply;

//     error InsufficientValue(uint256, uint256);
//     error InsufficientEscrow(uint256, uint256);
//     event Written(
//         uint256 cheqId,
//         address indexed owner,
//         uint256 escrowed,
//         uint256 createdAt
//     );

//     modifier isMinted(uint256 cheqId) {
//         if (cheqId >= _totalSupply) revert NotMinted();
//         _;
//     }

//     constructor() ERC721("denota", "NOTA") {}

//     /*/////////////////////// WTFCAT ////////////////////////////*/
//     function write(
//         address _currency,
//         uint256 escrowed,
//         address owner,
//         address module,
//         bytes calldata moduleWriteData
//     ) public payable returns (uint256) {
//         require(IERC20(tokenGate).balanceOf(account) > 0, "");
//         _transferTokens(escrowed, instant, _currency, owner, moduleFee, module);

//         _mint(owner, _totalSupply);
//         _cheqInfo[_totalSupply] = Nota(
//             escrowed,
//             block.timestamp,
//             currency,
//             module
//         );

//         emit Written(
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
//     ) public isMinted(cheqId) {
//         _transferHookTakeFee(from, to, cheqId, abi.encode(""));
//         _transfer(from, to, cheqId);
//     }

//     function fund(
//         uint256 cheqId,
//         uint256 amount,
//         uint256 instant,
//         bytes calldata fundData
//     ) public payable isMinted(cheqId) {
//         DataTypes.Nota storage cheq = _cheqInfo[cheqId]; // TODO module MUST check that token exists
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
//         DataTypes.Nota storage cheq = _cheqInfo[cheqId];

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

//     function approve(address to, uint256 cheqId) public isMinted(cheqId) {
//         if (to == _msgSender()) revert SelfApproval();

//         // Module hook
//         DataTypes.Nota memory cheq = _cheqInfo[cheqId];
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
//         DataTypes.Nota storage cheq = _cheqInfo[cheqId]; // Better to assign than to index?
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
//     ) public override(ERC721, INotaRegistrar) {
//         _transferHookTakeFee(from, to, cheqId, moduleTransferData);
//         _safeTransfer(from, to, cheqId, moduleTransferData);
//     }

//     /*///////////////////////// VIEW ////////////////////////////*/
//     function cheqInfo(
//         uint256 cheqId
//     ) public view returns (DataTypes.Nota memory) {
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

// contract GateFactory {
//     mapping(address => mapping(address => address)) public currencyGate;
//     address[] public currencyGates;

//     constructor() {}

//     function deploy(address currency, address gate) external {
//         Registrar registrar = new GateRegistrar();
//         deployerAddress[currency][gate] = address(registrar);
//         admins.push(address(registrar));
//     }
// }
