// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
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
//         _URI = __baseURI;
//     }

//     function processWrite(
//         address caller,
//         address owner,
//         uint256 cheqId,
//         DataTypes.Nota calldata cheq,
//         uint256 directAmount,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         IWriteRule(writeRule).canWrite(
//             caller,
//             owner,
//             cheqId,
//             cheq,
//             directAmount,
//             initData
//         );

//         (bytes32 memoHash, address referer) = abi.decode(
//             initData,
//             (bytes32, address)
//         ); // Frontend uploads (encrypted) memo document and the URI is linked to cheqId here (URI and content hash are set as the same)
//         memo[cheqId] = memoHash;

//         uint256 totalAmount = cheq.escrowed + directAmount;
//         uint256 moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
//         revenue[referer][cheq.currency] += moduleFee;

//         emit MemoWritten(cheqId, memoHash);
//         return moduleFee;
//     }

//     function processTransfer(
//         address caller,
//         bool isApproved,
//         address owner,
//         address from,
//         address to,
//         uint256 cheqId,
//         DataTypes.Nota calldata cheq,
//         bytes memory data
//     ) external override onlyRegistrar returns (uint256) {
//         ITransferRule(transferRule).canTransfer(
//             caller,
//             isApproved,
//             owner,
//             from,
//             to,
//             cheqId,
//             cheq,
//             data
//         );
//         require(isCashed[cheqId], "Module: Only after cashing");
//         uint256 moduleFee = (cheq.escrowed * fees.transferBPS) / BPS_MAX;
//         // revenue[referer][cheq.currency] += moduleFee; // TODO who does this go to if no bytes?
//         return moduleFee;
//     }

//     function processFund(
//         address caller,
//         address owner,
//         uint256 amount,
//         uint256 directAmount,
//         uint256 cheqId,
//         DataTypes.Nota calldata cheq,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         IFundRule(fundRule).canFund(
//             caller,
//             owner,
//             amount,
//             directAmount,
//             cheqId,
//             cheq,
//             initData
//         );
//         // require(!isCashed[cheqId], "Module: Already cashed");
//         address referer = abi.decode(initData, (address));
//         uint256 moduleFee = ((amount + directAmount) * fees.fundBPS) / BPS_MAX;
//         revenue[referer][cheq.currency] += moduleFee;
//         return moduleFee;
//     }

//     function processCash(
//         address caller,
//         address owner,
//         address to,
//         uint256 amount,
//         uint256 cheqId,
//         DataTypes.Nota calldata cheq,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         ICashRule(cashRule).canCash(
//             caller,
//             owner,
//             to,
//             amount,
//             cheqId,
//             cheq,
//             initData
//         );
//         // require(!isCashed[cheqId], "Module: Already cashed");
//         address referer = abi.decode(initData, (address));
//         uint256 moduleFee = (amount * fees.cashBPS) / BPS_MAX;
//         revenue[referer][cheq.currency] += moduleFee;
//         isCashed[cheqId] = true;
//         return moduleFee;
//     }

//     function processApproval(
//         address caller,
//         address owner,
//         address to,
//         uint256 cheqId,
//         DataTypes.Nota calldata cheq,
//         bytes memory initData
//     ) external override onlyRegistrar {
//         IApproveRule(approveRule).canApprove(
//             caller,
//             owner,
//             to,
//             cheqId,
//             cheq,
//             initData
//         );
//         // require(isCashed[cheqId], "Module: Must be cashed first");
//     }
// }
