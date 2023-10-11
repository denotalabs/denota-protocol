// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.14;

// import "openzeppelin/access/Ownable.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/// @notice allows whoever finds the correct hash to claim the written cheq
abstract contract PseudoChain is ModuleBase {
    //     mapping(uint256 => uint256) public blockCashTime;
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
    //         blockCashTime[0] = block.timestamp;
    //     }
    //     function processWrite(
    //         address caller,
    //         address owner,
    //         uint256 cheqId,
    //         DataTypes.Nota calldata cheq,
    //         uint256 directAmount,
    //         bytes calldata initData
    //     ) external override onlyRegistrar returns (uint256) {
    //         // require(blockCashTime[], "");
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
    //         blockCashTime[cheqId] = blockCashTime[cheqId - 1] + 1 days;
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
    //         ITransferRule(transferRule).canTransfer( // False, or isOwner
    //             caller,
    //             isApproved,
    //             owner,
    //             from,
    //             to,
    //             cheqId,
    //             cheq,
    //             data
    //         );
    //         uint256 moduleFee = (cheq.escrowed * fees.transferBPS) / BPS_MAX;
    //         return moduleFee;
    //     }
    //     //     function cashable(
    //     //         uint256 cheqId,
    //     //         address, /* caller */
    //     //         uint256 /* amount */
    //     //     ) public view returns (uint256) {
    //     //         if (false) {
    //     //             // "0"*n+"..." == keccack((keccack(cheqId) + hash)
    //     //             return cheq.cheqEscrowed(cheqId);
    //     //         } else {
    //     //             return 0;
    //     //         }
    //     //     }
    //     //     function cashNota(uint256 cheqId, uint256 amount) public {
    //     //         uint256 cashableAmount = cashable(cheqId, _msgSender(), amount);
    //     //         require(cashableAmount == amount, "Cant cash this amount");
    //     //         cheq.cash(cheqId, _msgSender(), amount);
    //     //     }
    //     //     function tokenURI(uint256 tokenId)
    //     //         public
    //     //         view
    //     //         override(ERC721, INotaModule)
    //     //         returns (string memory)
    //     //     {
    //     //         return string(abi.encodePacked(_baseURI(), tokenId));
    //     //     }
}

/// @notice allows the owner to fund and transfer or wait until the timelock is over
abstract contract PayItForward is ModuleBase {
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
}

/// @notice allows certain addresses the ability to cash
abstract contract SimpleLottery is ModuleBase {

}

/// @notice allows the owner to update the URI and memo hash (if they escrow more money?)
abstract contract URIUpdater is ModuleBase {

}

/// @notice write a cheq (to the zero address?) and the winner of a game (or other bet) gets to transfer to themselves and cash
abstract contract OracleRelease is ModuleBase {

}
