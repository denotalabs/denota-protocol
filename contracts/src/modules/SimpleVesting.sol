// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {Nota, WTFCFees} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";

/**
 * @notice Issuer pays out the entire escrow amount at once. Defines the size and times of each vest in the schedule.
 */
// contract SimpleVest is ModuleBase {
//     mapping(uint256 => bool) public isCashed;

//     constructor(
//         address registrar,
//         address _writeRule,
//         address _transferRule,
//         address _fundRule,
//         address _cashRule,
//         address _approveRule,
//         WTFCFees memory _fees,
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
//         _URI = __baseURI;
//     }

//     function processWrite(
//         address caller,
//         address owner,
//         uint256 notaId,
//         Nota calldata nota,
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

//         (bytes32 memoHash, address referer) = abi.decode(
//             initData,
//             (bytes32, address)
//         ); // Frontend uploads (encrypted) memo document and the URI is linked to notaId here (URI and content hash are set as the same)
//         memo[notaId] = memoHash;

//         uint256 totalAmount = nota.escrowed + directAmount;
//         uint256 moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
//         revenue[referer][nota.currency] += moduleFee;

//         emit MemoWritten(notaId, memoHash);
//         return moduleFee;
//     }

//     function processTransfer(
//         address caller,
//         bool isApproved,
//         address owner,
//         address from,
//         address to,
//         uint256 notaId,
//         Nota calldata nota,
//         bytes memory data
//     ) external override onlyRegistrar returns (uint256) {
//         ITransferRule(transferRule).canTransfer(
//             caller,
//             isApproved,
//             owner,
//             from,
//             to,
//             notaId,
//             nota,
//             data
//         );
//         require(isCashed[notaId], "Module: Only after cashing");
//         uint256 moduleFee = (nota.escrowed * fees.transferBPS) / BPS_MAX;
//         // revenue[referer][nota.currency] += moduleFee; // TODO who does this go to if no bytes?
//         return moduleFee;
//     }

//     function processFund(
//         address caller,
//         address owner,
//         uint256 amount,
//         uint256 directAmount,
//         uint256 notaId,
//         Nota calldata nota,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         IFundRule(fundRule).canFund(
//             caller,
//             owner,
//             amount,
//             directAmount,
//             notaId,
//             nota,
//             initData
//         );
//         // require(!isCashed[notaId], "Module: Already cashed");
//         address referer = abi.decode(initData, (address));
//         uint256 moduleFee = ((amount + directAmount) * fees.fundBPS) / BPS_MAX;
//         revenue[referer][nota.currency] += moduleFee;
//         return moduleFee;
//     }

//     function processCash(
//         address caller,
//         address owner,
//         address to,
//         uint256 amount,
//         uint256 notaId,
//         Nota calldata nota,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         ICashRule(cashRule).canCash(
//             caller,
//             owner,
//             to,
//             amount,
//             notaId,
//             nota,
//             initData
//         );
//         // require(!isCashed[notaId], "Module: Already cashed");
//         address referer = abi.decode(initData, (address));
//         uint256 moduleFee = (amount * fees.cashBPS) / BPS_MAX;
//         revenue[referer][nota.currency] += moduleFee;
//         isCashed[notaId] = true;
//         return moduleFee;
//     }

//     function processApproval(
//         address caller,
//         address owner,
//         address to,
//         uint256 notaId,
//         Nota calldata nota,
//         bytes memory initData
//     ) external override onlyRegistrar {
//         IApproveRule(approveRule).canApprove(
//             caller,
//             owner,
//             to,
//             notaId,
//             nota,
//             initData
//         );
//         // require(isCashed[notaId], "Module: Must be cashed first");
//     }
// }
