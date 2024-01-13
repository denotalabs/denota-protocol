// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// import {DirectPay} from "./../DirectPay.sol";
// import {DataTypes} from "../../libraries/DataTypes.sol";
// import {INotaRegistrar} from "../../interfaces/INotaRegistrar.sol";

// /**
//  * @notice multi-bounty module // IDEA comment out when not on polygon
//  */
// contract AttestationStation {
//     mapping(address => mapping(address => mapping(bytes32 => bytes)))
//         public attestations;

//     struct AttestationData {
//         address about;
//         bytes32 key;
//         bytes val;
//     }

//     event AttestationCreated(
//         address indexed creator,
//         address indexed about,
//         bytes32 indexed key,
//         bytes val
//     );

//     function attest(AttestationData[] memory _attestations) public {
//         for (uint256 i = 0; i < _attestations.length; ++i) {
//             AttestationData memory attestation = _attestations[i];
//             attestations[msg.sender][attestation.about][
//                 attestation.key
//             ] = attestation.val;
//             emit AttestationCreated(
//                 msg.sender,
//                 attestation.about,
//                 attestation.key,
//                 attestation.val
//             );
//         }
//     }
// }

// contract DirectPayBounty is DirectPay {
//     AttestationStation public AT_STAT; // IDEA comment out when not on polygon

//     constructor(
//         address registrar,
//         WTFCFees memory _fees,
//         string memory __baseURI,
//         AttestationStation _AT_STAT
//     ) DirectPay(registrar, _fees, __baseURI) {
//         AT_STAT = _AT_STAT; // IDEA comment out when not on polygon
//     }

//     function processWrite(
//         address caller,
//         address owner,
//         uint256 notaId,
//         address currency,
//         uint256 escrowed,
//         uint256 instant,
//         bytes calldata initData
//     ) public override onlyRegistrar returns (uint256) {
//         require(escrowed == 0, "Escrowing not supported");
//         (
//             address toNotify,
//             uint256 amount,
//             uint256 timestamp,
//             address dappOperator,
//             bytes32 memoHash
//         ) = abi.decode(initData, (address, uint256, uint256, address, bytes32));
//         require(amount != 0, "Amount == 0");
//         require(
//             instant == amount || instant == 0, // instant=0 is for invoicing
//             "Must send full"
//         );
//         if (caller == owner) {
//             payInfo[notaId].payee = caller;
//             payInfo[notaId].payer = toNotify;
//         } else {
//             require(instant == amount, "No payment");
//             payInfo[notaId].payee = toNotify;
//             payInfo[notaId].payer = caller;
//             payInfo[notaId].wasPaid = true;
//             attestPayment(owner, instant); // IDEA comment out when not on polygon
//         }
//         payInfo[notaId].amount = amount;
//         payInfo[notaId].timestamp = timestamp;
//         payInfo[notaId].memoHash = memoHash;
//         require(
//             owner == caller || owner == toNotify,
//             "caller != owner && owner != toNotify"
//         );
//         require(toNotify != address(0) && owner != address(0), "Zero address"); // TODO can be simplified

//         uint256 moduleFee;
//         {
//             uint256 totalAmount = escrowed + instant;
//             moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
//         }
//         revenue[dappOperator][currency] += moduleFee;

//         emit PaymentCreated(notaId, memoHash, amount, timestamp, dappOperator);
//         return moduleFee;
//     }

//     function processTransfer(
//         address caller,
//         address approved,
//         address owner,
//         address, /*from*/
//         address, /*to*/
//         uint256, /*notaId*/
//         address currency,
//         uint256 escrowed,
//         uint256, /*createdAt*/
//         bytes memory data
//     ) public override onlyRegistrar returns (uint256) {
//         require(
//             caller == owner || caller == approved,
//             "Only owner or approved"
//         );

//         // require(payInfo[notaId].wasPaid, "Module: Only after cashing");
//         uint256 moduleFee = (escrowed * fees.transferBPS) / BPS_MAX;
//         revenue[abi.decode(data, (address))][currency] += moduleFee; // TODO who does this go to if no bytes? Set to NotaRegistrarOwner
//         return moduleFee;
//     }

//     function processFund(
//         address caller,
//         address owner,
//         uint256 amount,
//         uint256 instant,
//         uint256 notaId,
//         Nota calldata nota,
//         bytes calldata initData
//     ) public override onlyRegistrar returns (uint256) {
//         require(amount == 0, "Only direct pay");
//         // require(caller != owner, "Owner doesn't fund");
//         require(caller == payInfo[notaId].payer, "Only drawer/recipient");
//         require(!payInfo[notaId].wasPaid, "Module: Already cashed");
//         require(instant == payInfo[notaId].amount, "Only full direct amount");
//         payInfo[notaId].wasPaid = true;
//         attestPayment(owner, instant); // IDEA comment out when not on polygon

//         uint256 moduleFee = ((amount + instant) * fees.fundBPS) / BPS_MAX;
//         revenue[abi.decode(initData, (address))][nota.currency] += moduleFee;
//         return moduleFee;
//     }

//     function attestPayment(address about, uint256 amount) internal {
//         // IDEA comment out when not on polygon
//         // Get previous amount of bounties claimed
//         bytes memory prevScore = AT_STAT.attestations(
//             address(this),
//             about,
//             bytes32("bounty-score:string")
//         );
//         uint256 newScore = uint256(bytes32(prevScore)) + amount;

//         AttestationStation.AttestationData[]
//             memory attestationDataArr = new AttestationStation.AttestationData[](
//                 1
//             );
//         AttestationStation.AttestationData
//             memory attestationData = AttestationStation.AttestationData({
//                 about: about,
//                 key: bytes32("bounty-score:string"),
//                 val: bytes(abi.encode(bytes32(newScore)))
//             });

//         attestationDataArr[0] = attestationData;
//         AT_STAT.attest(attestationDataArr);
//     }

//     function processCash(
//         address, /*caller*/
//         address, /*owner*/
//         address, /*to*/
//         uint256, /*amount*/
//         uint256, /*notaId*/
//         Nota calldata, /*nota*/
//         bytes calldata /*initData*/
//     ) public view override onlyRegistrar returns (uint256) {
//         require(false, "Disallowed");
//         // address referer = abi.decode(initData, (address));
//         // payInfo[notaId].wasPaid = true;
//         // uint256 moduleFee = (amount * fees.cashBPS) / BPS_MAX;
//         // revenue[referer][nota.currency] += moduleFee;
//         return 0;
//     }

//     function processApproval(
//         address caller,
//         address owner,
//         address, /*to*/
//         uint256, /*notaId*/
//         Nota calldata, /*nota*/
//         bytes memory /*initData*/
//     ) public view override onlyRegistrar {
//         require(caller == owner, "Only owner");
//         // require(wasPaid[notaId], "Module: Must be cashed first");
//     }
// }

// contract DirectPay is ModuleBase {
//     struct Payment {
//         address payee;
//         address payer;
//         uint256 amount; // Face value of the payment
//         uint256 timestamp; // Relevant timestamp
//         bytes32 memoHash;
//         bool wasPaid; // TODO is this needed if using instant pay?
//     }
//     mapping(uint256 => Payment) public payInfo;

//     event PaymentCreated(
//         uint256 notaId,
//         bytes32 memoHash,
//         uint256 amount,
//         uint256 timestamp,
//         address referer
//     );

//     constructor(
//         address registrar,
//         WTFCFees memory _fees,
//         string memory __baseURI
//     ) ModuleBase(registrar, _fees) {
//         _URI = __baseURI;
//     }

//     function processWrite(
//         address caller,
//         address owner,
//         uint256 notaId,
//         address currency,
//         uint256 escrowed,
//         uint256 instant,
//         bytes calldata initData
//     ) public override onlyRegistrar returns (uint256) {
//         require(escrowed == 0, "Escrowing not supported");
//         (
//             address toNotify,
//             uint256 amount,
//             uint256 timestamp,
//             address dappOperator,
//             bytes32 memoHash
//         ) = abi.decode(initData, (address, uint256, uint256, address, bytes32));
//         // caller, owner, recipient
//         require(amount != 0, "Amount == 0");
//         require(
//             instant == amount || instant == 0, // instant=0 is for invoicing
//             "Must send full"
//         );
//         if (caller == owner) {
//             payInfo[notaId].payee = caller;
//             payInfo[notaId].payer = toNotify;
//         } else {
//             require(instant == amount, "No payment");
//             payInfo[notaId].payee = toNotify;
//             payInfo[notaId].payer = caller;
//             payInfo[notaId].wasPaid = true;
//         }
//         payInfo[notaId].amount = amount;
//         payInfo[notaId].timestamp = timestamp;
//         payInfo[notaId].memoHash = memoHash;
//         // require(drawer != recipient, "Rule: Drawer == recipient");
//         require(
//             owner == caller || owner == toNotify,
//             "Drawer/recipient != owner"
//         );
//         require(toNotify != address(0) && owner != address(0), "Zero address"); // TODO can be simplified

//         uint256 moduleFee;
//         {
//             uint256 totalAmount = escrowed + instant;
//             moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
//         }
//         revenue[dappOperator][currency] += moduleFee;

//         emit PaymentCreated(notaId, memoHash, amount, timestamp, dappOperator);
//         return moduleFee;
//     }

//     function processTransfer(
//         address caller,
//         address approved,
//         address owner,
//         address, /*from*/
//         address, /*to*/
//         uint256, /*notaId*/
//         address currency,
//         uint256 escrowed,
//         uint256, /*createdAt*/
//         bytes memory data
//     ) public override onlyRegistrar returns (uint256) {
//         require(
//             caller == owner || caller == approved,
//             "Only owner or approved"
//         );

//         // require(payInfo[notaId].wasPaid, "Module: Only after cashing");
//         uint256 moduleFee = (escrowed * fees.transferBPS) / BPS_MAX;
//         revenue[abi.decode(data, (address))][currency] += moduleFee; // TODO who does this go to if no bytes? Set to NotaRegistrarOwner
//         return moduleFee;
//     }

//     function processFund(
//         address caller,
//         address, /*owner*/
//         uint256 amount,
//         uint256 instant,
//         uint256 notaId,
//         Nota calldata nota,
//         bytes calldata initData
//     ) public override onlyRegistrar returns (uint256) {
//         require(amount == 0, "Only direct pay");
//         // require(caller != owner, "Owner doesn't fund");
//         require(caller == payInfo[notaId].payer, "Only drawer/recipient");
//         require(!payInfo[notaId].wasPaid, "Module: Already cashed");
//         require(instant == payInfo[notaId].amount, "Only full direct amount");
//         payInfo[notaId].wasPaid = true;
//         uint256 moduleFee = ((amount + instant) * fees.fundBPS) / BPS_MAX;
//         revenue[abi.decode(initData, (address))][nota.currency] += moduleFee;
//         return moduleFee;
//     }

//     function processCash(
//         address, /*caller*/
//         address, /*owner*/
//         address, /*to*/
//         uint256, /*amount*/
//         uint256, /*notaId*/
//         Nota calldata, /*nota*/
//         bytes calldata /*initData*/
//     ) public view override onlyRegistrar returns (uint256) {
//         require(false, "Rule: Disallowed");
//         // address referer = abi.decode(initData, (address));
//         // payInfo[notaId].wasPaid = true;
//         // uint256 moduleFee = (amount * fees.cashBPS) / BPS_MAX;
//         // revenue[referer][nota.currency] += moduleFee;
//         return 0;
//     }

//     function processApproval(
//         address, /*caller*/
//         address, /*owner*/
//         address, /*to*/
//         uint256, /*notaId*/
//         Nota calldata, /*nota*/
//         bytes memory /*initData*/
//     ) public view override onlyRegistrar {
//         require(false, "Rule: Disallowed");
//         // require(wasPaid[notaId], "Module: Must be cashed first");
//     }

//     function processTokenURI(uint256 tokenId)
//         external
//         view
//         override
//         returns (string memory)
//     {
//         return string(abi.encodePacked(_URI, payInfo[tokenId].memoHash));
//     }
// }
