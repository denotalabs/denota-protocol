// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
// import "openzeppelin/utils/Strings.sol";
// import "openzeppelin/access/Ownable.sol";
// import "openzeppelin/token/ERC20/IERC20.sol";
// import "openzeppelin/token/ERC721/ERC721.sol";
// import {ModuleBase} from "../ModuleBase.sol";
// import {DataTypes} from "../libraries/DataTypes.sol";

// contract HandshakeTimeLock is ModuleBase {
//     //     mapping(address => mapping(address => bool)) public userAuditor; // Whether User accepts Auditor
//     //     mapping(address => mapping(address => bool)) public auditorUser; // Whether Auditor accepts User
//     //     mapping(uint256 => uint256) public inspectionPeriod;
//     //     mapping(uint256 => address) public notaAuditor;
//     //     mapping(address => bool) public notaVoided;
//     //     string private _baseURI;

//     constructor(
//         address registrar,
//         DataTypes.WTFCFees memory _fees,
//         string memory __baseURI
//     ) ModuleBase(registrar, _fees) {
//         _URI = __baseURI;
//     }

//     // TRANSFERING
//     //         (address auditor, uint256 _inspectionPeriod) = abi.decode(initData, (address, uint256));
//     //         require(userAuditor[caller][auditor] && auditorUser[auditor][caller], "Must handshake");
//     //         inspectionPeriod[notaId] = _inspectionPeriod;
//     //         notaAuditor[notaId] = auditor;

//     // FUNDING
//     //         require(inspectionPeriod[notaId] + nota.mintTimestamp <= block.timestamp, "Already cashed");  // How to abstract this?

//     // CASHING
//     // //         if (block.timestamp >= notaCreated[notaId]+notaInspectionPeriod[notaId]
//     // //             || crx.ownerOf(notaId)!=caller
//     // //             || notaVoided[notaId]){
//     // //             return 0;
//     // //         } else{
//     // //             return crx.notaEscrowed(notaId);
//     // //         }
//     // require(!notaVoided[notaId], "Voided");
//     // notaVoided[notaId] = true;

//     //     function tokenURI(uint256 /*tokenId*/) external pure returns (string memory){
//     //         return "";
//     //     }

//     //     function voidnota(uint256 notaId) external {
//     //         require(notaAuditor[notaId]==_msgSender(), "Only auditor");
//     //         notaVoided[notaId] = true;
//     //         // crx.cash(notaId, crx.notaDrawer(notaId), crx.notaEscrowed(notaId));  // Return escrow to drawer
//     //     }
//     //     function status(uint256 notaId, address caller) public view returns(string memory){
//     //         if(cashable(notaId, caller) != 0){
//     //             return "mature";
//     //         } else if(notaVoided[notaId]){
//     //             return "voided";
//     //         } else {
//     //             return "pending";
//     //         }
//     //     }
// }
