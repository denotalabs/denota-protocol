// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/utils/Strings.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {ICheqModule} from "../interfaces/ICheqModule.sol";
import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

/**
 * Question: How to ensure deployed modules point to correct CheqRegistrar and Globals?
 * TODO how to export the struct?
 * Notice: Assumes only invoices are sent
 * Notice: Assumes milestones are funded sequentially
 * @notice Contract: stores invoice structs, takes/sends WTFC fees to owner, allows owner to set URI, allows freelancer/client to set work status',
 */
// contract Marketplace is ModuleBase, Ownable {
//     using Strings for uint256;
//     // `InProgress` might not need to be explicit (Invoice.workerStatus=ready && Invoice.clientStatus=ready == working)
//     // QUESTION: Should this pertain to the current milestone??
//     enum Status {
//         Waiting,
//         Ready,
//         InProgress,
//         Disputing,
//         Resolved,
//         Finished
//     }
//     // Question: Should milestones have a startTime? What about Statuses?
//     // Question: Whether and how to track multiple milestone funding?
//     struct Milestone {
//         uint256 price; // Amount the milestone is worth
//         bool workerFinished; // Could pack these bools more
//         bool clientReleased;
//         bool workerCashed;
//     }
//     // Can add expected completion date and refund partial to relevant party if late
//     struct Invoice {
//         // TODO can optimize these via smaller types and packing
//         address drawer;
//         address recipient;
//         uint256 startTime;
//         uint256 currentMilestone;
//         uint256 totalMilestones;
//         Status workerStatus;
//         Status clientStatus;
//         bytes32 documentHash;
//     }
//     // mapping(uint256 => uint256) public inspectionPeriods; // Would this give the reversibility period?
//     mapping(uint256 => Invoice) public invoices;
//     mapping(uint256 => Milestone[]) public milestones;
//     mapping(address => bool) public tokenWhitelist;

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
//     }

//     function whitelistToken(address token, bool whitelist) public onlyOwner {
//         tokenWhitelist[token] = whitelist;
//     }

//     function setBaseURI(string calldata __baseURI) external onlyOwner {
//         _URI = __baseURI;
//     }

//     function processWrite(
//         address caller,
//         address owner,
//         uint256 cheqId,
//         DataTypes.Cheq calldata cheq,
//         uint256 instant,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         // Writes milestones to mapping, writes totalMilestones into invoice (rest of invoice is filled out later)
//         require(tokenWhitelist[cheq.currency], "Module: Token not whitelisted"); // QUESTION: should this be a require or return false?
//         IWriteRule(writeRule).canWrite(
//             caller,
//             owner,
//             cheqId,
//             cheq,
//             instant,
//             initData
//         ); // Should the assumption be that this is only for freelancers to send as an invoice??
//         // require(caller == owner, "Not invoice");
//         // require(cheq.drawer == caller, "Can't send on behalf");
//         // require(cheq.recipient != owner, "Can't self send");
//         // require(cheq.amount > 0, "Can't send cheq with 0 value");

//         // require(milestonePrices.sum() == cheq.amount);

//         (
//             address drawer,
//             address recipient,
//             bytes32 documentHash,
//             uint256[] memory milestonePrices
//         ) = abi.decode(initData, (address, address, bytes32, uint256[]));
//         uint256 numMilestones = milestonePrices.length;
//         require(numMilestones > 1, "Module: Insufficient milestones"); // First milestone is upfront payment

//         for (uint256 i = 0; i < numMilestones; i++) {
//             milestones[cheqId].push(
//                 Milestone({
//                     price: milestonePrices[i],
//                     workerFinished: false,
//                     clientReleased: false,
//                     workerCashed: false
//                 })
//             ); // Can optimize on gas much more
//         }
//         invoices[cheqId].drawer = drawer;
//         invoices[cheqId].recipient = recipient;
//         invoices[cheqId].documentHash = documentHash;
//         invoices[cheqId].totalMilestones = numMilestones;
//         return fees.writeBPS;
//     }

//     function processTransfer(
//         address caller,
//         address approved,
//         address owner,
//         address from,
//         address to,
//         uint256 cheqId,
//         DataTypes.Cheq calldata cheq,
//         bytes memory initData
//     ) external override onlyRegistrar returns (uint256) {
//         ITransferRule(transferRule).canTransfer(
//             caller,
//             approved,
//             owner,
//             from,
//             to,
//             cheqId,
//             cheq,
//             initData
//         ); // Checks if caller is ownerOrApproved
//         return fees.transferBPS;
//     }

//     // QUESTION: Who should/shouldn't be allowed to fund?
//     // QUESTION: Should `amount` throw on milestone[currentMilestone].price != amount or tell registrar correct amount?
//     // QUESTION: Should funder be able to fund whatever amounts they want?
//     // QUESTION: Should funding transfer the money to the client?? Or client must claim?
//     function processFund(
//         address caller,
//         address owner,
//         uint256 amount,
//         uint256 instant,
//         uint256 cheqId,
//         DataTypes.Cheq calldata cheq,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         // Client escrows the first milestone (is the upfront)
//         // Must be milestone[0] price (currentMilestone == 0)
//         // increment currentMilestone (client can cash previous milestone)
//         //

//         /**
//         struct Milestone {
//             uint256 price;  // Amount the milestone is worth
//             bool workerFinished;  // Could pack these bools more
//             bool clientReleased;
//             bool workerCashed;
//         }
//         // Can add expected completion date and refund partial to relevant party if late
//         struct Invoice {
//             uint256 startTime;
//             uint256 currentMilestone;
//             uint256 totalMilestones;
//             Status workerStatus;
//             Status clientStatus;
//             // bytes32 documentHash;
//         }
//          */
//         // require(caller == cheq.recipient, "Module: Only client can fund");
//         IFundRule(fundRule).canFund(
//             caller,
//             owner,
//             amount,
//             instant,
//             cheqId,
//             cheq,
//             initData
//         );

//         if (invoices[cheqId].startTime == 0)
//             invoices[cheqId].startTime = block.timestamp;

//         invoices[cheqId].clientStatus = Status.Ready;

//         uint256 oldMilestone = invoices[cheqId].currentMilestone;
//         require(
//             amount == milestones[cheqId][oldMilestone].price,
//             "Module: Incorrect milestone amount"
//         ); // Question should module throw on insufficient fund or enforce the amount?
//         milestones[cheqId][oldMilestone].workerFinished = true;
//         milestones[cheqId][oldMilestone].clientReleased = true;
//         invoices[cheqId].currentMilestone += 1;
//         return fees.fundBPS;
//     }

//     function processCash(
//         // Must allow the funder to cash the escrows too
//         address caller,
//         address owner,
//         address to,
//         uint256 amount,
//         uint256 cheqId,
//         DataTypes.Cheq calldata cheq,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         // require(caller == owner, "");
//         ICashRule(cashRule).canCash(
//             caller,
//             owner,
//             to,
//             amount,
//             cheqId,
//             cheq,
//             initData
//         );
//         require(
//             invoices[cheqId].currentMilestone > 0,
//             "Module: Can't cash yet"
//         );
//         uint256 lastMilestone = invoices[cheqId].currentMilestone - 1;
//         milestones[cheqId][lastMilestone].workerCashed = true; //
//         return fees.cashBPS;
//     }

//     function processApproval(
//         address caller,
//         address owner,
//         address to,
//         uint256 cheqId,
//         DataTypes.Cheq calldata cheq,
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

//     // function processOwnerOf(address owner, uint256 tokenId) external view returns(bool) {}

//     function processTokenURI(uint256 tokenId)
//         public
//         view
//         override
//         onlyRegistrar
//         returns (string memory)
//     {
//         string memory __baseURI = _baseURI();
//         return
//             bytes(__baseURI).length > 0
//                 ? string(abi.encodePacked(_URI, tokenId.toString()))
//                 : "";
//     }

//     /*//////////////////////////////////////////////////////////////
//                             Module Functions
//     //////////////////////////////////////////////////////////////*/
//     function _baseURI() internal view returns (string memory) {
//         return _URI;
//     }

//     function getMilestones(uint256 cheqId)
//         public
//         view
//         returns (Milestone[] memory)
//     {
//         return milestones[cheqId];
//     }

//     function setStatus(uint256 cheqId, Status newStatus) public {
//         Invoice storage invoice = invoices[cheqId];

//         // (address drawer, address recipient) = ICheqRegistrar(REGISTRAR)
//         //     .cheqDrawerRecipient(cheqId);
//         require(
//             _msgSender() == invoices[cheqId].drawer ||
//                 _msgSender() == invoices[cheqId].recipient,
//             "Module: Unauthorized"
//         );

//         bool isWorker = _msgSender() == invoices[cheqId].drawer;
//         Status oldStatus = isWorker
//             ? invoice.workerStatus
//             : invoice.clientStatus;

//         require(
//             oldStatus < newStatus ||
//                 (oldStatus == Status.Resolved && newStatus == Status.Disputing),
//             "Module: Status not allowed"
//         ); // Parties can change resolved back to disputed and back to in progress
//         if (isWorker) {
//             invoice.workerStatus = newStatus;
//         } else {
//             invoice.clientStatus = newStatus;
//         }

//         // Can Resolved lead to continued work (Status.Working) or pay out based on the resolution?
//         // If one doesn't set theirs to disputed, should the arbitor only be allowed to payout the party with Status.Disputed?
//     }

//     function getFees()
//         public
//         view
//         override
//         returns (
//             uint256,
//             uint256,
//             uint256,
//             uint256
//         )
//     {
//         return (fees.writeBPS, fees.transferBPS, fees.fundBPS, fees.cashBPS);
//     }
// }

// (/*uint256 startTime, Status workerStatus, Status clientStatus, */Milestone[] memory milestones) = abi.decode(initData, (/*uint256, Status, Status,*/ Milestone[]));
// require(milestones.length > 0, "No milestones");
// // Really only need milestone price array for each milestone
// // invoices[cheqId].startTime = startTime;
// // invoices[cheqId].workerStatus = workerStatus;
// // invoices[cheqId].clientStatus = clientStatus;
// for (uint256 i = 0; i < milestones.length; i++){ // invoices[cheqId].milestones = milestones;
//     invoices[cheqId].milestones.push(milestones[i]);  // Can optimize on gas much more
// }
// (uint256 startTime, Status workerStatus, Status clientStatus) = abi.decode(initData, (uint256, Status, Status));

// // BUG what if funder doesnt fund the invoice for too long??
// function cashable(
//     uint256 cheqId,
//     address caller,
//     uint256 /* amount */
// ) public view returns (uint256) {
//     // Invoice funder can cash before period, cheq writer can cash before period
//     // Chargeback case
//     if (
//         cheqFunder[cheqId] == caller &&
//         (block.timestamp <
//             cheqCreated[cheqId] + cheqInspectionPeriod[cheqId])
//     ) {
//         // Funding party can rescind before the inspection period elapses
//         return cheq.cheqEscrowed(cheqId);
//     } else if (
//         cheq.ownerOf(cheqId) == caller &&
//         (block.timestamp >=
//             cheqCreated[cheqId] + cheqInspectionPeriod[cheqId])
//     ) {
//         // Receiving/Owning party can cash after inspection period
//         return cheq.cheqEscrowed(cheqId);
//     } else if (isReleased[cheqId]) {
//         return cheq.cheqEscrowed(cheqId);
//     } else {
//         return 0;
//     }
// }
