// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// import {ModuleBase} from "../ModuleBase.sol";
// import {DataTypes} from "../libraries/DataTypes.sol";
// import {INotaModule} from "../interfaces/INotaModule.sol";
// import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";

// /**
//  * @notice
//  */
// contract GiftCard is ModuleBase {
//     mapping(uint256 => bytes32) public dataHash;
//     event DataWritten(uint256 cheqId, bytes32 dataHash);

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
//         address currency,
//         uint256 escrowed,
//         uint256 instant,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         IWriteRule(writeRule).canWrite(
//             caller,
//             owner,
//             cheqId,
//             currency,
//             escrowed,
//             instant,
//             initData
//         );

//         (bytes32 hashedData, address referer) = abi.decode(
//             initData,
//             (bytes32, address)
//         ); // Frontend uploads (encrypted) memo document and the URI is linked to cheqId here (URI and content hash are set as the same)
//         dataHash[cheqId] = hashedData;

//         uint256 totalAmount = escrowed + instant;
//         uint256 moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
//         revenue[referer][currency] += moduleFee;

//         emit DataWritten(cheqId, hashedData);
//         return moduleFee;
//     }

//     function processTransfer(
//         address caller,
//         address approved,
//         address owner,
//         address from,
//         address to,
//         uint256 cheqId,
//         address currency,
//         uint256 escrowed,
//         uint256 createdAt,
//         bytes memory data
//     ) external override onlyRegistrar returns (uint256) {
//         // ITransferRule(transferRule).canTransfer(
//         //     caller,
//         //     approved,
//         //     owner,
//         //     from,
//         //     to,
//         //     cheqId,
//         //     currency,
//         //     escrowed,
//         //     data
//         // );
//         uint256 moduleFee = (escrowed * fees.transferBPS) / BPS_MAX;
//         // revenue[referer][cheq.currency] += moduleFee; // TODO who does this go to if no bytes?
//         return moduleFee;
//     }

//     function processFund(
//         address caller,
//         address owner,
//         uint256 amount,
//         uint256 instant,
//         uint256 cheqId,
//         DataTypes.Nota calldata cheq,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         IFundRule(fundRule).canFund(
//             caller,
//             owner,
//             amount,
//             instant,
//             cheqId,
//             cheq,
//             initData
//         );
//         // require(!isCashed[cheqId], "Module: Already cashed");
//         address referer = abi.decode(initData, (address));
//         uint256 moduleFee = ((amount + instant) * fees.fundBPS) / BPS_MAX;
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
//         uint256 moduleFee = (amount * fees.cashBPS) / BPS_MAX;
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
//     }
// }
