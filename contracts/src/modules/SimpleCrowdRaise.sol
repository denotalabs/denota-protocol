// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";

/**
 * @notice A simple crowdfunding module
 * The owner is raising, sets an end date, and can't cash unless its fully funded and before the end date.
 * If end date passes and fully funded, only the owner can cash. Otherwise only the funders can
 */
// contract SimpleCrowdRaise is ModuleBase {
//     mapping(uint256 => bytes32) public dataHash;
//     event DataWritten(uint256 notaId, bytes32 dataHash);

//     // mapping(uint256 => bool) public isCashed;

//     // mapping(uint256 => uint256) public endDate;
//     // mapping(uint256 => mapping(address => uint256)) funderAmount;

//     constructor(
//         address registrar,
//         address _writeRule,
//         address _transferRule,
//         address _fundRule,
//         address _cashRule,
//         address _approveRule,
//         DataTypes.WTFCFees memory _fees,
//         string memory __baseURI
//     )
//         ModuleBase(
//             registrar,
//             _writeRule,
//             _transferRule,
//             _fundRule,
//             _cashRule,
//             _approveRule,
//             _fees
//         )
//     {
//         // ERC721("SSTL", "SelfSignTimeLock") TODO: enumuration/registration of module features (like Lens?)
//         _URI = __baseURI;
//         fees = _fees;
//     }

//     function processWrite(
//         address caller,
//         address owner,
//         uint256 notaId,
//         DataTypes.Nota calldata nota,
//         uint256 directAmount,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         IWriteRule(writeRule).canWrite(
//             caller,
//             owner,
//             notaId,
//             nota,
//             directAmount,
//             initData
//         );
//         // require(nota.escrowed == 0, "");

//         bytes32 memoHash = abi.decode(initData, (bytes32)); // Frontend uploads (encrypted) memo document and the URI is linked to notaId here (URI and content hash are set as the same)
//         memo[notaId] = memoHash;

//         emit MemoWritten(notaId, memoHash);

//         return fees.writeBPS;
//     }

//     function processTransfer(
//         address caller,
//         bool isApproved,
//         address owner,
//         address from,
//         address to,
//         uint256 notaId,
//         DataTypes.Nota calldata nota,
//         bytes memory data
//     ) external override onlyRegistrar returns (uint256) {
//         require(isCashed[notaId], "Needs full funding");
//         ITransferRule(transferRule).canTransfer(
//             caller,
//             isApproved,
//             owner,
//             from,
//             to,
//             notaId,
//             nota,
//             data
//         ); // Checks if caller is ownerOrApproved
//         return fees.transferBPS;
//     }

//     function processFund(
//         address caller,
//         address owner,
//         uint256 amount,
//         uint256 directAmount,
//         uint256 notaId,
//         DataTypes.Nota calldata nota,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         require(!isCashed[notaId], "Already cashed"); // How to abstract this?
//         // require(endDate[notaId] <= block.timestamp, "Funding over");
//         // require(nota.escrowed + amount <= nota.amount, "Overfunding");
//         IFundRule(fundRule).canFund(
//             caller,
//             owner,
//             amount,
//             directAmount,
//             notaId,
//             nota,
//             initData
//         );
//         // uint256 fundAmount = nota.escrowed + amount <= nota.amount ? amount : nota.amount - nota.escrowed;
//         return fees.fundBPS;
//     }

//     function processCash(
//         address caller,
//         address owner,
//         address to,
//         uint256 amount,
//         uint256 notaId,
//         DataTypes.Nota calldata nota,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         require(!isCashed[notaId], "Already cashed");
//         ICashRule(cashRule).canCash(
//             caller,
//             owner,
//             to,
//             amount,
//             notaId,
//             nota,
//             initData
//         );
//         isCashed[notaId] = true;
//         // require(nota.escrowed == nota.amount, "");
//         return fees.cashBPS;
//     }

//     function processApproval(
//         address caller,
//         address owner,
//         address to,
//         uint256 notaId,
//         DataTypes.Nota calldata nota,
//         bytes memory initData
//     ) external override onlyRegistrar {
//         require(isCashed[notaId], "Must be cashed first");
//         IApproveRule(approveRule).canApprove(
//             caller,
//             owner,
//             to,
//             notaId,
//             nota,
//             initData
//         );
//     }

//     function processTokenURI(uint256 tokenId)
//         external
//         view
//         override
//         returns (string memory)
//     {
//         // Allow nota creator to update the URI?
//         bytes32 memoHash = memo[tokenId];
//         return string(abi.encodePacked(_URI, memoHash)); // ipfs://baseURU/memoHash --> memo // TODO encrypt upload on frontend
//     }
// }
