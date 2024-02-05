// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.14;

// import "openzeppelin/access/Ownable.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";

/// @notice allows whoever finds the correct hash to claim the written nota
abstract contract PseudoChain is ModuleBase {
    //     mapping(uint256 => uint256) public blockCashTime;

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
}

/// @notice allows the owner to fund and transfer or wait until the timelock is over
abstract contract PayItForward is ModuleBase {
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
    mapping(uint256 notaId => address factory) public factories;
    constructor(address _registrar) ModuleBase(_registrar) {
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

abstract contract CashCondition is ModuleBase {
    // Allow this contract to call to another contract's view function to allow owner to cash
}

abstract contract LimitedTimeCash is ModuleBase {
    // Allow this contract to call to another contract's view function to allow owner to cash
}

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

// /// @notice allows sender to set the attestation requirements for new owners. Allows them to update URIs too
// contract AttestSendLock is ModuleBase {
//     // mapping(address(this) => mapping(senderAddress => mapping(recipAddress => amountBytes))) public creditAttestations;
//     // mapping(attestingAddress => mapping(aboutAddress => mapping(key => valueBytes))) public creditAttestations;
//     struct Gate {
//         address attSource;
//         bytes32 key;
//         uint256 index;
//         bytes32 expectedVal;
//     }

//     AttestationStation public AT_STAT;
//     mapping(uint256 => Gate) public attestGates;
//     mapping(uint256 => bytes) public tokenURIs;

//     function _onlyAttestation(
//         address about,
//         address attester,
//         bytes32 key,
//         uint256 index,
//         bytes32 expectedVal
//     ) internal view {
//         require(
//             AT_STAT.attestations(attester, about, key)[index] == expectedVal,
//             "Not attested"
//         );
//     }

//     modifier onlyAttested(address about, uint256 notaId) {
//         _onlyAttestation(
//             attestGates[notaId].attSource,
//             about,
//             attestGates[notaId].key,
//             attestGates[notaId].index,
//             attestGates[notaId].expectedVal
//         );
//         _;
//     }

//     constructor(
//         address registrar
//     ) ModuleBase(registrar) {
//     }

//     function processWrite(
//         address caller,
//         address owner,
//         uint256 notaId,
//         address currency,
//         uint256 escrowed,
//         uint256 instant,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         require(
//             owner != address(0) && caller != owner,
//             "Address zero or self-own"
//         );

//         (
//             address attSource,
//             bytes32 key,
//             uint256 index,
//             bytes32 expectedVal,
//             address dappOperator
//         ) = abi.decode(initData, (address, bytes32, uint256, bytes32, address));

//         _onlyAttestation(attSource, owner, key, index, expectedVal);

//         attestGates[notaId].attSource = attSource;
//         attestGates[notaId].key = key;
//         attestGates[notaId].index = index;
//         attestGates[notaId].expectedVal = expectedVal;

//         return 0;
//     }

//     function processTransfer(
//         address /*caller*/,
//         address /*approved*/,
//         address /*owner*/,
//         address /*from*/,
//         address to,
//         uint256 notaId,
//         address /*currency*/,
//         uint256 escrowed,
//         uint256 /*createdAt*/,
//         bytes memory /*data*/
//     )
//         external
//         view
//         override
//         onlyRegistrar
//         onlyAttested(to, notaId)
//         returns (uint256)
//     {
//         // return _takeReturnFee(currency, escrowed, dappOperator);
//         return 0;
//     }

//     function processFund(
//         address caller,
//         address owner,
//         uint256 amount,
//         uint256 instant,
//         uint256 notaId,
//         Nota calldata nota,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         require(caller == owner, "Not owner");
//         return 0;
//     }

//     function processCash(
//         address /*caller*/,
//         address /*owner*/,
//         address /*to*/,
//         uint256 amount,
//         uint256 /*notaId*/,
//         Nota calldata nota,
//         bytes calldata initData
//     ) external override onlyRegistrar returns (uint256) {
//         return 0;
//     }

//     function processApproval(
//         address /*caller*/,
//         address /*owner*/,
//         address /*to*/,
//         uint256 /*notaId*/,
//         Nota calldata /*nota*/,
//         bytes memory /*initData*/
//     ) external view override onlyRegistrar {}

//     function processTokenURI(
//         uint256 tokenId
//     ) external view virtual override returns (string memory) {
//         return string(tokenURIs[tokenId]);
//     }

//     function updateURI(uint256 notaId, bytes calldata newURI) public {
//         require(msg.sender == ERC721(REGISTRAR).ownerOf(notaId), "Only Owner");
//         tokenURIs[notaId] = newURI;
//     }
// }
