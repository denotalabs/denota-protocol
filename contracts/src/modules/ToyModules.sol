// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.14;

// import "openzeppelin/access/Ownable.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/// @notice allows whoever finds the correct hash to claim the written nota
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
    //         uint256 notaId,
    //         DataTypes.Nota calldata nota,
    //         uint256 directAmount,
    //         bytes calldata initData
    //     ) external override onlyRegistrar returns (uint256) {
    //         // require(blockCashTime[], "");
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
    //         blockCashTime[notaId] = blockCashTime[notaId - 1] + 1 days;
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
    //         DataTypes.Nota calldata nota,
    //         bytes memory data
    //     ) external override onlyRegistrar returns (uint256) {
    //         ITransferRule(transferRule).canTransfer( // False, or isOwner
    //             caller,
    //             isApproved,
    //             owner,
    //             from,
    //             to,
    //             notaId,
    //             nota,
    //             data
    //         );
    //         uint256 moduleFee = (nota.escrowed * fees.transferBPS) / BPS_MAX;
    //         return moduleFee;
    //     }
    //     //     function cashable(
    //     //         uint256 notaId,
    //     //         address, /* caller */
    //     //         uint256 /* amount */
    //     //     ) public view returns (uint256) {
    //     //         if (false) {
    //     //             // "0"*n+"..." == keccack((keccack(notaId) + hash)
    //     //             return nota.notaEscrowed(notaId);
    //     //         } else {
    //     //             return 0;
    //     //         }
    //     //     }
    //     //     function cashnota(uint256 notaId, uint256 amount) public {
    //     //         uint256 cashableAmount = cashable(notaId, _msgSender(), amount);
    //     //         require(cashableAmount == amount, "Cant cash this amount");
    //     //         nota.cash(notaId, _msgSender(), amount);
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

/// @notice write a nota (to the zero address?) and the winner of a game (or other bet) gets to transfer to themselves and cash
abstract contract OracleRelease is ModuleBase {

}
