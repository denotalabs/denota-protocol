// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.14;

// import "openzeppelin/access/Ownable.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";

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
    //         blockCashTime[0] = block.timestamp;
    //     }
    //     function processWrite(
    //         address caller,
    //         address owner,
    //         uint256 notaId,
    //         Nota calldata nota,
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
    //         Nota calldata nota,
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

abstract contract HashFinder is ModuleBase {
// You could pay someone for finding the right salt for a hook address. Make module that tracks bytecode(hash?) => reward. Person writes Nota with the correct salt, it's verified and then the module releases the money
    address factory;
    constructor(address _factory) {
        factory = _factory;
    }

    function verifyHash() public returns(bool success){
        // address _address = keccak(Salt, bytecode, address)
        // significant_digits 
        // Get if the address is correct for the hool calls they want
    }

}

/// @notice disputation mechanism is a settlement time w/ an extension if disputed. This can be counter disputed until one party gives up
abstract contract DisputeVolley is ModuleBase {

}
abstract contract Subscription is ModuleBase {}

/// @notice Sender pays reciever and can spite where the sender gets back the money after X amount of time
abstract contract SpiteLockup is ModuleBase {

}

abstract contract SimpleNFTGate is ModuleBase {}

abstract contract SimpleCrowdRaise is ModuleBase {}

/// @notice allows the module owner to pause functionalities
abstract contract SimpleAdmin is /*Pausable,*/ ModuleBase {

}

/// @notice allows the nota creator to set an admin that can pause WTFC for that particular nota
abstract contract SetAdmin is ModuleBase {

}

// Require both sender and receiver to approve each other
abstract contract HandshakeTimeLock is ModuleBase {}