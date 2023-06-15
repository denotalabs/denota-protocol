// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity ^0.8.16;

// import {ModuleBase} from "../ModuleBase.sol";
// import {DataTypes} from "../libraries/DataTypes.sol";
// import {ICheqModule} from "../interfaces/ICheqModule.sol";
// import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

// /// @notice disputation mechanism is a settlement time w/ an extension if disputed. This can be counter disputed until one party gives up
// abstract contract DisputeVolley is ModuleBase {

// }

// pragma solidity ^0.8.16;

// // import {ModuleBase} from "../ModuleBase.sol";
// // import {DataTypes} from "../libraries/DataTypes.sol";
// // import {ICheqModule} from "../interfaces/ICheqModule.sol";
// // import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

// // /**
// //  * @notice
// //  */
// // contract GiftCard is ModuleBase {
// //     mapping(uint256 => bytes32) public dataHash;
// //     event DataWritten(uint256 cheqId, bytes32 dataHash);

// //     constructor(
// //         address registrar,
// //         address _writeRule,
// //         address _transferRule,
// //         address _fundRule,
// //         address _cashRule,
// //         address _approveRule,
// //         DataTypes.WTFCFees memory _fees,
// //         string memory __baseURI
// //     )
// //         ModuleBase(
// //             registrar,
// //             _writeRule,
// //             _transferRule,
// //             _fundRule,
// //             _cashRule,
// //             _approveRule,
// //             _fees
// //         )
// //     {
// //         _URI = __baseURI;
// //     }

// //     function processWrite(
// //         address caller,
// //         address owner,
// //         uint256 cheqId,
// //         address currency,
// //         uint256 escrowed,
// //         uint256 instant,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         IWriteRule(writeRule).canWrite(
// //             caller,
// //             owner,
// //             cheqId,
// //             currency,
// //             escrowed,
// //             instant,
// //             initData
// //         );

// //         (bytes32 hashedData, address referer) = abi.decode(
// //             initData,
// //             (bytes32, address)
// //         ); // Frontend uploads (encrypted) memo document and the URI is linked to cheqId here (URI and content hash are set as the same)
// //         dataHash[cheqId] = hashedData;

// //         uint256 totalAmount = escrowed + instant;
// //         uint256 moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
// //         revenue[referer][currency] += moduleFee;

// //         emit DataWritten(cheqId, hashedData);
// //         return moduleFee;
// //     }

// //     function processTransfer(
// //         address caller,
// //         address approved,
// //         address owner,
// //         address from,
// //         address to,
// //         uint256 cheqId,
// //         address currency,
// //         uint256 escrowed,
// //         uint256 createdAt,
// //         bytes memory data
// //     ) external override onlyRegistrar returns (uint256) {
// //         // ITransferRule(transferRule).canTransfer(
// //         //     caller,
// //         //     approved,
// //         //     owner,
// //         //     from,
// //         //     to,
// //         //     cheqId,
// //         //     currency,
// //         //     escrowed,
// //         //     data
// //         // );
// //         uint256 moduleFee = (escrowed * fees.transferBPS) / BPS_MAX;
// //         // revenue[referer][cheq.currency] += moduleFee; // TODO who does this go to if no bytes?
// //         return moduleFee;
// //     }

// //     function processFund(
// //         address caller,
// //         address owner,
// //         uint256 amount,
// //         uint256 instant,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         IFundRule(fundRule).canFund(
// //             caller,
// //             owner,
// //             amount,
// //             instant,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //         // require(!isCashed[cheqId], "Module: Already cashed");
// //         address referer = abi.decode(initData, (address));
// //         uint256 moduleFee = ((amount + instant) * fees.fundBPS) / BPS_MAX;
// //         revenue[referer][cheq.currency] += moduleFee;
// //         return moduleFee;
// //     }

// //     function processCash(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 amount,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         ICashRule(cashRule).canCash(
// //             caller,
// //             owner,
// //             to,
// //             amount,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //         uint256 moduleFee = (amount * fees.cashBPS) / BPS_MAX;
// //         return moduleFee;
// //     }

// //     function processApproval(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes memory initData
// //     ) external override onlyRegistrar {
// //         IApproveRule(approveRule).canApprove(
// //             caller,
// //             owner,
// //             to,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //     }
// // }

// pragma solidity ^0.8.16;
// // import "openzeppelin/utils/Strings.sol";
// // import "openzeppelin/access/Ownable.sol";
// // import "openzeppelin/token/ERC20/IERC20.sol";
// // import "openzeppelin/token/ERC721/ERC721.sol";
// // import {ModuleBase} from "../ModuleBase.sol";
// // import {DataTypes} from "../libraries/DataTypes.sol";

// // contract HandshakeTimeLock is ModuleBase {
// //     //     mapping(address => mapping(address => bool)) public userAuditor; // Whether User accepts Auditor
// //     //     mapping(address => mapping(address => bool)) public auditorUser; // Whether Auditor accepts User
// //     //     mapping(uint256 => uint256) public inspectionPeriod;
// //     //     mapping(uint256 => address) public cheqAuditor;
// //     //     mapping(address => bool) public cheqVoided;
// //     //     string private _baseURI;

// //     constructor(
// //         address registrar,
// //         DataTypes.WTFCFees memory _fees,
// //         string memory __baseURI
// //     ) ModuleBase(registrar, _fees) {
// //         _URI = __baseURI;
// //     }

// //     // TRANSFERING
// //     //         (address auditor, uint256 _inspectionPeriod) = abi.decode(initData, (address, uint256));
// //     //         require(userAuditor[caller][auditor] && auditorUser[auditor][caller], "Must handshake");
// //     //         inspectionPeriod[cheqId] = _inspectionPeriod;
// //     //         cheqAuditor[cheqId] = auditor;

// //     // FUNDING
// //     //         require(inspectionPeriod[cheqId] + cheq.mintTimestamp <= block.timestamp, "Already cashed");  // How to abstract this?

// //     // CASHING
// //     // //         if (block.timestamp >= cheqCreated[cheqId]+cheqInspectionPeriod[cheqId]
// //     // //             || crx.ownerOf(cheqId)!=caller
// //     // //             || cheqVoided[cheqId]){
// //     // //             return 0;
// //     // //         } else{
// //     // //             return crx.cheqEscrowed(cheqId);
// //     // //         }
// //     // require(!cheqVoided[cheqId], "Voided");
// //     // cheqVoided[cheqId] = true;

// //     //     function tokenURI(uint256 /*tokenId*/) external pure returns (string memory){
// //     //         return "";
// //     //     }

// //     //     function voidCheq(uint256 cheqId) external {
// //     //         require(cheqAuditor[cheqId]==_msgSender(), "Only auditor");
// //     //         cheqVoided[cheqId] = true;
// //     //         // crx.cash(cheqId, crx.cheqDrawer(cheqId), crx.cheqEscrowed(cheqId));  // Return escrow to drawer
// //     //     }
// //     //     function status(uint256 cheqId, address caller) public view returns(string memory){
// //     //         if(cashable(cheqId, caller) != 0){
// //     //             return "mature";
// //     //         } else if(cheqVoided[cheqId]){
// //     //             return "voided";
// //     //         } else {
// //     //             return "pending";
// //     //         }
// //     //     }
// // }


// pragma solidity ^0.8.16;
// import "openzeppelin/utils/Strings.sol";
// import "openzeppelin/token/ERC20/IERC20.sol";
// import "openzeppelin/access/Ownable.sol";
// import {ModuleBase} from "../ModuleBase.sol";
// import {DataTypes} from "../libraries/DataTypes.sol";
// import {ICheqModule} from "../interfaces/ICheqModule.sol";
// import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

// /**
//  * Question: How to ensure deployed modules point to correct CheqRegistrar and Globals?
//  * TODO how to export the struct?
//  * Notice: Assumes only invoices are sent
//  * Notice: Assumes milestones are funded sequentially
//  * @notice Contract: stores invoice structs, takes/sends WTFC fees to owner, allows owner to set URI, allows freelancer/client to set work status',
//  */
// // contract Marketplace is ModuleBase, Ownable {
// //     using Strings for uint256;
// //     // `InProgress` might not need to be explicit (Invoice.workerStatus=ready && Invoice.clientStatus=ready == working)
// //     // QUESTION: Should this pertain to the current milestone??
// //     enum Status {
// //         Waiting,
// //         Ready,
// //         InProgress,
// //         Disputing,
// //         Resolved,
// //         Finished
// //     }
// //     // Question: Should milestones have a startTime? What about Statuses?
// //     // Question: Whether and how to track multiple milestone funding?
// //     struct Milestone {
// //         uint256 price; // Amount the milestone is worth
// //         bool workerFinished; // Could pack these bools more
// //         bool clientReleased;
// //         bool workerCashed;
// //     }
// //     // Can add expected completion date and refund partial to relevant party if late
// //     struct Invoice {
// //         // TODO can optimize these via smaller types and packing
// //         address drawer;
// //         address recipient;
// //         uint256 startTime;
// //         uint256 currentMilestone;
// //         uint256 totalMilestones;
// //         Status workerStatus;
// //         Status clientStatus;
// //         bytes32 documentHash;
// //     }
// //     // mapping(uint256 => uint256) public inspectionPeriods; // Would this give the reversibility period?
// //     mapping(uint256 => Invoice) public invoices;
// //     mapping(uint256 => Milestone[]) public milestones;
// //     mapping(address => bool) public tokenWhitelist;

// //     constructor(
// //         address registrar,
// //         address _writeRule,
// //         address _transferRule,
// //         address _fundRule,
// //         address _cashRule,
// //         address _approveRule,
// //         DataTypes.WTFCFees memory _fees,
// //         string memory __baseURI
// //     )
// //         ModuleBase(
// //             registrar,
// //             _writeRule,
// //             _transferRule,
// //             _fundRule,
// //             _cashRule,
// //             _approveRule,
// //             _fees
// //         )
// //     {
// //         // ERC721("SSTL", "SelfSignTimeLock") TODO: enumuration/registration of module features (like Lens?)
// //         _URI = __baseURI;
// //     }

// //     function whitelistToken(address token, bool whitelist) public onlyOwner {
// //         tokenWhitelist[token] = whitelist;
// //     }

// //     function setBaseURI(string calldata __baseURI) external onlyOwner {
// //         _URI = __baseURI;
// //     }

// //     function processWrite(
// //         address caller,
// //         address owner,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         uint256 instant,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         // Writes milestones to mapping, writes totalMilestones into invoice (rest of invoice is filled out later)
// //         require(tokenWhitelist[cheq.currency], "Module: Token not whitelisted"); // QUESTION: should this be a require or return false?
// //         IWriteRule(writeRule).canWrite(
// //             caller,
// //             owner,
// //             cheqId,
// //             cheq,
// //             instant,
// //             initData
// //         ); // Should the assumption be that this is only for freelancers to send as an invoice??
// //         // require(caller == owner, "Not invoice");
// //         // require(cheq.drawer == caller, "Can't send on behalf");
// //         // require(cheq.recipient != owner, "Can't self send");
// //         // require(cheq.amount > 0, "Can't send cheq with 0 value");

// //         // require(milestonePrices.sum() == cheq.amount);

// //         (
// //             address drawer,
// //             address recipient,
// //             bytes32 documentHash,
// //             uint256[] memory milestonePrices
// //         ) = abi.decode(initData, (address, address, bytes32, uint256[]));
// //         uint256 numMilestones = milestonePrices.length;
// //         require(numMilestones > 1, "Module: Insufficient milestones"); // First milestone is upfront payment

// //         for (uint256 i = 0; i < numMilestones; i++) {
// //             milestones[cheqId].push(
// //                 Milestone({
// //                     price: milestonePrices[i],
// //                     workerFinished: false,
// //                     clientReleased: false,
// //                     workerCashed: false
// //                 })
// //             ); // Can optimize on gas much more
// //         }
// //         invoices[cheqId].drawer = drawer;
// //         invoices[cheqId].recipient = recipient;
// //         invoices[cheqId].documentHash = documentHash;
// //         invoices[cheqId].totalMilestones = numMilestones;
// //         return fees.writeBPS;
// //     }

// //     function processTransfer(
// //         address caller,
// //         address approved,
// //         address owner,
// //         address from,
// //         address to,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes memory initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         ITransferRule(transferRule).canTransfer(
// //             caller,
// //             approved,
// //             owner,
// //             from,
// //             to,
// //             cheqId,
// //             cheq,
// //             initData
// //         ); // Checks if caller is ownerOrApproved
// //         return fees.transferBPS;
// //     }

// //     // QUESTION: Who should/shouldn't be allowed to fund?
// //     // QUESTION: Should `amount` throw on milestone[currentMilestone].price != amount or tell registrar correct amount?
// //     // QUESTION: Should funder be able to fund whatever amounts they want?
// //     // QUESTION: Should funding transfer the money to the client?? Or client must claim?
// //     function processFund(
// //         address caller,
// //         address owner,
// //         uint256 amount,
// //         uint256 instant,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         // Client escrows the first milestone (is the upfront)
// //         // Must be milestone[0] price (currentMilestone == 0)
// //         // increment currentMilestone (client can cash previous milestone)
// //         //

// //         /**
// //         struct Milestone {
// //             uint256 price;  // Amount the milestone is worth
// //             bool workerFinished;  // Could pack these bools more
// //             bool clientReleased;
// //             bool workerCashed;
// //         }
// //         // Can add expected completion date and refund partial to relevant party if late
// //         struct Invoice {
// //             uint256 startTime;
// //             uint256 currentMilestone;
// //             uint256 totalMilestones;
// //             Status workerStatus;
// //             Status clientStatus;
// //             // bytes32 documentHash;
// //         }
// //          */
// //         // require(caller == cheq.recipient, "Module: Only client can fund");
// //         IFundRule(fundRule).canFund(
// //             caller,
// //             owner,
// //             amount,
// //             instant,
// //             cheqId,
// //             cheq,
// //             initData
// //         );

// //         if (invoices[cheqId].startTime == 0)
// //             invoices[cheqId].startTime = block.timestamp;

// //         invoices[cheqId].clientStatus = Status.Ready;

// //         uint256 oldMilestone = invoices[cheqId].currentMilestone;
// //         require(
// //             amount == milestones[cheqId][oldMilestone].price,
// //             "Module: Incorrect milestone amount"
// //         ); // Question should module throw on insufficient fund or enforce the amount?
// //         milestones[cheqId][oldMilestone].workerFinished = true;
// //         milestones[cheqId][oldMilestone].clientReleased = true;
// //         invoices[cheqId].currentMilestone += 1;
// //         return fees.fundBPS;
// //     }

// //     function processCash(
// //         // Must allow the funder to cash the escrows too
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 amount,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         // require(caller == owner, "");
// //         ICashRule(cashRule).canCash(
// //             caller,
// //             owner,
// //             to,
// //             amount,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //         require(
// //             invoices[cheqId].currentMilestone > 0,
// //             "Module: Can't cash yet"
// //         );
// //         uint256 lastMilestone = invoices[cheqId].currentMilestone - 1;
// //         milestones[cheqId][lastMilestone].workerCashed = true; //
// //         return fees.cashBPS;
// //     }

// //     function processApproval(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes memory initData
// //     ) external override onlyRegistrar {
// //         IApproveRule(approveRule).canApprove(
// //             caller,
// //             owner,
// //             to,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //     }

// //     // function processOwnerOf(address owner, uint256 tokenId) external view returns(bool) {}

// //     function processTokenURI(uint256 tokenId)
// //         public
// //         view
// //         override
// //         onlyRegistrar
// //         returns (string memory)
// //     {
// //         string memory __baseURI = _baseURI();
// //         return
// //             bytes(__baseURI).length > 0
// //                 ? string(abi.encodePacked(_URI, tokenId.toString()))
// //                 : "";
// //     }

// //     /*//////////////////////////////////////////////////////////////
// //                             Module Functions
// //     //////////////////////////////////////////////////////////////*/
// //     function _baseURI() internal view returns (string memory) {
// //         return _URI;
// //     }

// //     function getMilestones(uint256 cheqId)
// //         public
// //         view
// //         returns (Milestone[] memory)
// //     {
// //         return milestones[cheqId];
// //     }

// //     function setStatus(uint256 cheqId, Status newStatus) public {
// //         Invoice storage invoice = invoices[cheqId];

// //         // (address drawer, address recipient) = ICheqRegistrar(REGISTRAR)
// //         //     .cheqDrawerRecipient(cheqId);
// //         require(
// //             _msgSender() == invoices[cheqId].drawer ||
// //                 _msgSender() == invoices[cheqId].recipient,
// //             "Module: Unauthorized"
// //         );

// //         bool isWorker = _msgSender() == invoices[cheqId].drawer;
// //         Status oldStatus = isWorker
// //             ? invoice.workerStatus
// //             : invoice.clientStatus;

// //         require(
// //             oldStatus < newStatus ||
// //                 (oldStatus == Status.Resolved && newStatus == Status.Disputing),
// //             "Module: Status not allowed"
// //         ); // Parties can change resolved back to disputed and back to in progress
// //         if (isWorker) {
// //             invoice.workerStatus = newStatus;
// //         } else {
// //             invoice.clientStatus = newStatus;
// //         }

// //         // Can Resolved lead to continued work (Status.Working) or pay out based on the resolution?
// //         // If one doesn't set theirs to disputed, should the arbitor only be allowed to payout the party with Status.Disputed?
// //     }

// //     function getFees()
// //         public
// //         view
// //         override
// //         returns (
// //             uint256,
// //             uint256,
// //             uint256,
// //             uint256
// //         )
// //     {
// //         return (fees.writeBPS, fees.transferBPS, fees.fundBPS, fees.cashBPS);
// //     }
// // }

// // (/*uint256 startTime, Status workerStatus, Status clientStatus, */Milestone[] memory milestones) = abi.decode(initData, (/*uint256, Status, Status,*/ Milestone[]));
// // require(milestones.length > 0, "No milestones");
// // // Really only need milestone price array for each milestone
// // // invoices[cheqId].startTime = startTime;
// // // invoices[cheqId].workerStatus = workerStatus;
// // // invoices[cheqId].clientStatus = clientStatus;
// // for (uint256 i = 0; i < milestones.length; i++){ // invoices[cheqId].milestones = milestones;
// //     invoices[cheqId].milestones.push(milestones[i]);  // Can optimize on gas much more
// // }
// // (uint256 startTime, Status workerStatus, Status clientStatus) = abi.decode(initData, (uint256, Status, Status));

// // // BUG what if funder doesnt fund the invoice for too long??
// // function cashable(
// //     uint256 cheqId,
// //     address caller,
// //     uint256 /* amount */
// // ) public view returns (uint256) {
// //     // Invoice funder can cash before period, cheq writer can cash before period
// //     // Chargeback case
// //     if (
// //         cheqFunder[cheqId] == caller &&
// //         (block.timestamp <
// //             cheqCreated[cheqId] + cheqInspectionPeriod[cheqId])
// //     ) {
// //         // Funding party can rescind before the inspection period elapses
// //         return cheq.cheqEscrowed(cheqId);
// //     } else if (
// //         cheq.ownerOf(cheqId) == caller &&
// //         (block.timestamp >=
// //             cheqCreated[cheqId] + cheqInspectionPeriod[cheqId])
// //     ) {
// //         // Receiving/Owning party can cash after inspection period
// //         return cheq.cheqEscrowed(cheqId);
// //     } else if (isReleased[cheqId]) {
// //         return cheq.cheqEscrowed(cheqId);
// //     } else {
// //         return 0;
// //     }
// // }


// pragma solidity ^0.8.16;

// import {ModuleBase} from "../ModuleBase.sol";
// import {DataTypes} from "../libraries/DataTypes.sol";
// import {ICheqModule} from "../interfaces/ICheqModule.sol";
// import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

// /**
//  * @notice A simple crowdfunding module
//  * The owner is raising, sets an end date, and can't cash unless its fully funded and before the end date.
//  * If end date passes and fully funded, only the owner can cash. Otherwise only the funders can
//  */
// // contract SimpleCrowdRaise is ModuleBase {
// //     mapping(uint256 => bytes32) public dataHash;
// //     event DataWritten(uint256 cheqId, bytes32 dataHash);

// //     // mapping(uint256 => bool) public isCashed;

// //     // mapping(uint256 => uint256) public endDate;
// //     // mapping(uint256 => mapping(address => uint256)) funderAmount;

// //     constructor(
// //         address registrar,
// //         address _writeRule,
// //         address _transferRule,
// //         address _fundRule,
// //         address _cashRule,
// //         address _approveRule,
// //         DataTypes.WTFCFees memory _fees,
// //         string memory __baseURI
// //     )
// //         ModuleBase(
// //             registrar,
// //             _writeRule,
// //             _transferRule,
// //             _fundRule,
// //             _cashRule,
// //             _approveRule,
// //             _fees
// //         )
// //     {
// //         // ERC721("SSTL", "SelfSignTimeLock") TODO: enumuration/registration of module features (like Lens?)
// //         _URI = __baseURI;
// //         fees = _fees;
// //     }

// //     function processWrite(
// //         address caller,
// //         address owner,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         uint256 directAmount,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         IWriteRule(writeRule).canWrite(
// //             caller,
// //             owner,
// //             cheqId,
// //             cheq,
// //             directAmount,
// //             initData
// //         );
// //         // require(cheq.escrowed == 0, "");

// //         bytes32 memoHash = abi.decode(initData, (bytes32)); // Frontend uploads (encrypted) memo document and the URI is linked to cheqId here (URI and content hash are set as the same)
// //         memo[cheqId] = memoHash;

// //         emit MemoWritten(cheqId, memoHash);

// //         return fees.writeBPS;
// //     }

// //     function processTransfer(
// //         address caller,
// //         bool isApproved,
// //         address owner,
// //         address from,
// //         address to,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes memory data
// //     ) external override onlyRegistrar returns (uint256) {
// //         require(isCashed[cheqId], "Needs full funding");
// //         ITransferRule(transferRule).canTransfer(
// //             caller,
// //             isApproved,
// //             owner,
// //             from,
// //             to,
// //             cheqId,
// //             cheq,
// //             data
// //         ); // Checks if caller is ownerOrApproved
// //         return fees.transferBPS;
// //     }

// //     function processFund(
// //         address caller,
// //         address owner,
// //         uint256 amount,
// //         uint256 directAmount,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         require(!isCashed[cheqId], "Already cashed"); // How to abstract this?
// //         // require(endDate[cheqId] <= block.timestamp, "Funding over");
// //         // require(cheq.escrowed + amount <= cheq.amount, "Overfunding");
// //         IFundRule(fundRule).canFund(
// //             caller,
// //             owner,
// //             amount,
// //             directAmount,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //         // uint256 fundAmount = cheq.escrowed + amount <= cheq.amount ? amount : cheq.amount - cheq.escrowed;
// //         return fees.fundBPS;
// //     }

// //     function processCash(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 amount,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         require(!isCashed[cheqId], "Already cashed");
// //         ICashRule(cashRule).canCash(
// //             caller,
// //             owner,
// //             to,
// //             amount,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //         isCashed[cheqId] = true;
// //         // require(cheq.escrowed == cheq.amount, "");
// //         return fees.cashBPS;
// //     }

// //     function processApproval(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes memory initData
// //     ) external override onlyRegistrar {
// //         require(isCashed[cheqId], "Must be cashed first");
// //         IApproveRule(approveRule).canApprove(
// //             caller,
// //             owner,
// //             to,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //     }

// //     function processTokenURI(uint256 tokenId)
// //         external
// //         view
// //         override
// //         returns (string memory)
// //     {
// //         // Allow cheq creator to update the URI?
// //         bytes32 memoHash = memo[tokenId];
// //         return string(abi.encodePacked(_URI, memoHash)); // ipfs://baseURU/memoHash --> memo // TODO encrypt upload on frontend
// //     }
// // }


// pragma solidity ^0.8.16;

// import {ModuleBase} from "../ModuleBase.sol";
// import {DataTypes} from "../libraries/DataTypes.sol";
// import {ICheqModule} from "../interfaces/ICheqModule.sol";
// import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

// /**
//  * @notice A simple time release module. The longer the release time, the more in fees you have to pay
//  * Escrowed tokens are cashable after the releaseDate
//  * Question: Allow cheq creator to update the URI?
//  */
// contract SimpleTimelockFee is ModuleBase {
//     mapping(uint256 => uint256) public releaseDate;
//     event Timelock(uint256 cheqId, uint256 _releaseDate);

//     constructor(
//         address registrar,
//         DataTypes.WTFCFees memory _fees,
//         string memory __baseURI
//     ) ModuleBase(registrar, _fees) {
//         _URI = __baseURI;
//     }

//     function processWrite(
//         address /*caller*/,
//         address /*owner*/,
//         uint256 cheqId,
//         address currency,
//         uint256 escrowed,
//         uint256 instant,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         (uint256 _releaseDate, address dappOperator) = abi.decode(
//             initData,
//             (uint256, address)
//         ); // Frontend uploads (encrypted) memo document and the URI is linked to cheqId here (URI and content hash are set as the same)
//         releaseDate[cheqId] = _releaseDate;
//         emit Timelock(cheqId, _releaseDate);
//         return takeReturnFee(currency, escrowed + instant, dappOperator, 0);
//     }

//     function processTransfer(
//         address caller,
//         address approved,
//         address owner,
//         address /*from*/,
//         address /*to*/,
//         uint256 /*cheqId*/,
//         address currency,
//         uint256 escrowed,
//         uint256 /*createdAt*/,
//         bytes memory data
//     ) external override onlyRegistrar returns (uint256) {
//         require(caller == owner || caller == approved, "Not owner or approved");
//         return
//             takeReturnFee(currency, escrowed, abi.decode(data, (address)), 1);
//     }

//     function processFund(
//         address /*caller*/,
//         address /*owner*/,
//         uint256 /*amount*/,
//         uint256 /*instant*/,
//         uint256 /*cheqId*/,
//         DataTypes.Cheq calldata /*cheq*/,
//         bytes calldata /*initData*/
//     ) external view override onlyRegistrar returns (uint256) {
//         require(false, "Only sending and cashing");
//         return 0;
//     }

//     function processCash(
//         address /*caller*/,
//         address /*owner*/,
//         address /*to*/,
//         uint256 amount,
//         uint256 /*cheqId*/,
//         DataTypes.Cheq calldata cheq,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         require(amount == cheq.escrowed, "Must fully cash");
//         return
//             takeReturnFee(
//                 cheq.currency,
//                 amount,
//                 abi.decode(initData, (address)),
//                 3
//             );
//     }

//     function processApproval(
//         address caller,
//         address owner,
//         address /*to*/,
//         uint256 /*cheqId*/,
//         DataTypes.Cheq calldata /*cheq*/,
//         bytes memory /*initData*/
//     ) external view override onlyRegistrar {
//         require(caller == owner, "Only owner can approve");
//     }

//     function processTokenURI(
//         uint256 tokenId
//     ) external view override returns (string memory) {
//         return string(abi.encodePacked(_URI, tokenId));
//     }
// }


// pragma solidity ^0.8.16;

// import "openzeppelin/security/Pausable.sol";
// import {ModuleBase} from "../ModuleBase.sol";
// import {DataTypes} from "../libraries/DataTypes.sol";
// import {ICheqModule} from "../interfaces/ICheqModule.sol";
// import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

// /// @notice allows the module owner to pause functionalities
// abstract contract SimpleAdmin is Pausable, ModuleBase {

// }

// /// @notice allows the cheq creator to set an admin that can pause WTFC for that particular cheq
// abstract contract SetAdmin is ModuleBase {

// }


// pragma solidity ^0.8.16;

// import {ModuleBase} from "../ModuleBase.sol";
// import {DataTypes} from "../libraries/DataTypes.sol";
// import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

// /**
//  * @notice Issuer pays out the entire escrow amount at once. Defines the size and times of each vest in the schedule.
//  */
// // contract SimpleVest is ModuleBase {
// //     mapping(uint256 => bool) public isCashed;

// //     constructor(
// //         address registrar,
// //         address _writeRule,
// //         address _transferRule,
// //         address _fundRule,
// //         address _cashRule,
// //         address _approveRule,
// //         DataTypes.WTFCFees memory _fees,
// //         string memory __baseURI
// //     )
// //         ModuleBase(
// //             registrar,
// //             _writeRule,
// //             _transferRule,
// //             _fundRule,
// //             _cashRule,
// //             _approveRule,
// //             _fees
// //         )
// //     {
// //         _URI = __baseURI;
// //     }

// //     function processWrite(
// //         address caller,
// //         address owner,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         uint256 directAmount,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         IWriteRule(writeRule).canWrite(
// //             caller,
// //             owner,
// //             cheqId,
// //             cheq,
// //             directAmount,
// //             initData
// //         );

// //         (bytes32 memoHash, address referer) = abi.decode(
// //             initData,
// //             (bytes32, address)
// //         ); // Frontend uploads (encrypted) memo document and the URI is linked to cheqId here (URI and content hash are set as the same)
// //         memo[cheqId] = memoHash;

// //         uint256 totalAmount = cheq.escrowed + directAmount;
// //         uint256 moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
// //         revenue[referer][cheq.currency] += moduleFee;

// //         emit MemoWritten(cheqId, memoHash);
// //         return moduleFee;
// //     }

// //     function processTransfer(
// //         address caller,
// //         bool isApproved,
// //         address owner,
// //         address from,
// //         address to,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes memory data
// //     ) external override onlyRegistrar returns (uint256) {
// //         ITransferRule(transferRule).canTransfer(
// //             caller,
// //             isApproved,
// //             owner,
// //             from,
// //             to,
// //             cheqId,
// //             cheq,
// //             data
// //         );
// //         require(isCashed[cheqId], "Module: Only after cashing");
// //         uint256 moduleFee = (cheq.escrowed * fees.transferBPS) / BPS_MAX;
// //         // revenue[referer][cheq.currency] += moduleFee; // TODO who does this go to if no bytes?
// //         return moduleFee;
// //     }

// //     function processFund(
// //         address caller,
// //         address owner,
// //         uint256 amount,
// //         uint256 directAmount,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         IFundRule(fundRule).canFund(
// //             caller,
// //             owner,
// //             amount,
// //             directAmount,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //         // require(!isCashed[cheqId], "Module: Already cashed");
// //         address referer = abi.decode(initData, (address));
// //         uint256 moduleFee = ((amount + directAmount) * fees.fundBPS) / BPS_MAX;
// //         revenue[referer][cheq.currency] += moduleFee;
// //         return moduleFee;
// //     }

// //     function processCash(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 amount,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes calldata initData
// //     ) external override onlyRegistrar returns (uint256) {
// //         ICashRule(cashRule).canCash(
// //             caller,
// //             owner,
// //             to,
// //             amount,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //         // require(!isCashed[cheqId], "Module: Already cashed");
// //         address referer = abi.decode(initData, (address));
// //         uint256 moduleFee = (amount * fees.cashBPS) / BPS_MAX;
// //         revenue[referer][cheq.currency] += moduleFee;
// //         isCashed[cheqId] = true;
// //         return moduleFee;
// //     }

// //     function processApproval(
// //         address caller,
// //         address owner,
// //         address to,
// //         uint256 cheqId,
// //         DataTypes.Cheq calldata cheq,
// //         bytes memory initData
// //     ) external override onlyRegistrar {
// //         IApproveRule(approveRule).canApprove(
// //             caller,
// //             owner,
// //             to,
// //             cheqId,
// //             cheq,
// //             initData
// //         );
// //         // require(isCashed[cheqId], "Module: Must be cashed first");
// //     }
// // }

// /// @notice Sender pays reciever and can spite where the sender gets back the money after X amount of time
// abstract contract SpiteLockup is ModuleBase {

// }

// abstract contract Subscription is ModuleBase {}

// /// @notice allows whoever finds the correct hash to claim the written cheq
// abstract contract PseudoChain is ModuleBase {
//     //     mapping(uint256 => uint256) public blockCashTime;
//     //     constructor(
//     //         address registrar,
//     //         address _writeRule,
//     //         address _transferRule,
//     //         address _fundRule,
//     //         address _cashRule,
//     //         address _approveRule,
//     //         DataTypes.WTFCFees memory _fees,
//     //         string memory __baseURI
//     //     )
//     //         ModuleBase(
//     //             registrar,
//     //             _writeRule,
//     //             _transferRule,
//     //             _fundRule,
//     //             _cashRule,
//     //             _approveRule,
//     //             _fees
//     //         )
//     //     {
//     //         _URI = __baseURI;
//     //         blockCashTime[0] = block.timestamp;
//     //     }
//     //     function processWrite(
//     //         address caller,
//     //         address owner,
//     //         uint256 cheqId,
//     //         DataTypes.Cheq calldata cheq,
//     //         uint256 directAmount,
//     //         bytes calldata initData
//     //     ) external override onlyRegistrar returns (uint256) {
//     //         // require(blockCashTime[], "");
//     //         IWriteRule(writeRule).canWrite(
//     //             caller,
//     //             owner,
//     //             cheqId,
//     //             cheq,
//     //             directAmount,
//     //             initData
//     //         );
//     //         (bytes32 memoHash, address referer) = abi.decode(
//     //             initData,
//     //             (bytes32, address)
//     //         ); // Frontend uploads (encrypted) memo document and the URI is linked to cheqId here (URI and content hash are set as the same)
//     //         memo[cheqId] = memoHash;
//     //         blockCashTime[cheqId] = blockCashTime[cheqId - 1] + 1 days;
//     //         uint256 totalAmount = cheq.escrowed + directAmount;
//     //         uint256 moduleFee = (totalAmount * fees.writeBPS) / BPS_MAX;
//     //         revenue[referer][cheq.currency] += moduleFee;
//     //         emit MemoWritten(cheqId, memoHash);
//     //         return moduleFee;
//     //     }
//     //     function processTransfer(
//     //         address caller,
//     //         bool isApproved,
//     //         address owner,
//     //         address from,
//     //         address to,
//     //         uint256 cheqId,
//     //         DataTypes.Cheq calldata cheq,
//     //         bytes memory data
//     //     ) external override onlyRegistrar returns (uint256) {
//     //         ITransferRule(transferRule).canTransfer( // False, or isOwner
//     //             caller,
//     //             isApproved,
//     //             owner,
//     //             from,
//     //             to,
//     //             cheqId,
//     //             cheq,
//     //             data
//     //         );
//     //         uint256 moduleFee = (cheq.escrowed * fees.transferBPS) / BPS_MAX;
//     //         return moduleFee;
//     //     }
//     //     //     function cashable(
//     //     //         uint256 cheqId,
//     //     //         address, /* caller */
//     //     //         uint256 /* amount */
//     //     //     ) public view returns (uint256) {
//     //     //         if (false) {
//     //     //             // "0"*n+"..." == keccack((keccack(cheqId) + hash)
//     //     //             return cheq.cheqEscrowed(cheqId);
//     //     //         } else {
//     //     //             return 0;
//     //     //         }
//     //     //     }
//     //     //     function cashCheq(uint256 cheqId, uint256 amount) public {
//     //     //         uint256 cashableAmount = cashable(cheqId, _msgSender(), amount);
//     //     //         require(cashableAmount == amount, "Cant cash this amount");
//     //     //         cheq.cash(cheqId, _msgSender(), amount);
//     //     //     }
//     //     //     function tokenURI(uint256 tokenId)
//     //     //         public
//     //     //         view
//     //     //         override(ERC721, ICheqModule)
//     //     //         returns (string memory)
//     //     //     {
//     //     //         return string(abi.encodePacked(_baseURI(), tokenId));
//     //     //     }
// }

// /// @notice allows the owner to fund and transfer or wait until the timelock is over
// abstract contract PayItForward is ModuleBase {
//     //     constructor(
//     //         address registrar,
//     //         address _writeRule,
//     //         address _transferRule,
//     //         address _fundRule,
//     //         address _cashRule,
//     //         address _approveRule,
//     //         DataTypes.WTFCFees memory _fees,
//     //         string memory __baseURI
//     //     )
//     //         ModuleBase(
//     //             registrar,
//     //             _writeRule,
//     //             _transferRule,
//     //             _fundRule,
//     //             _cashRule,
//     //             _approveRule,
//     //             _fees
//     //         )
//     //     {
//     //         _URI = __baseURI;
//     //     }
// }

// /// @notice allows certain addresses the ability to cash
// abstract contract SimpleLottery is ModuleBase {

// }

// /// @notice allows the owner to update the URI and memo hash (if they escrow more money?)
// abstract contract URIUpdater is ModuleBase {

// }

// /// @notice write a cheq (to the zero address?) and the winner of a game (or other bet) gets to transfer to themselves and cash
// abstract contract OracleRelease is ModuleBase {

// }
