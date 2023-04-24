// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {ModuleBase} from "../ModuleBase.sol";
import "openzeppelin/token/ERC721/ERC721.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {ICheqModule} from "../interfaces/ICheqModule.sol";
import {ICheqRegistrar} from "../interfaces/ICheqRegistrar.sol";

contract AttestationStation {
    mapping(address => mapping(address => mapping(bytes32 => bytes)))
        public attestations;

    struct AttestationData {
        address about;
        bytes32 key;
        bytes val;
    }

    event AttestationCreated(
        address indexed creator,
        address indexed about,
        bytes32 indexed key,
        bytes val
    );

    function attest(AttestationData[] memory _attestations) public {
        for (uint256 i = 0; i < _attestations.length; ++i) {
            AttestationData memory attestation = _attestations[i];
            attestations[msg.sender][attestation.about][
                attestation.key
            ] = attestation.val;
            emit AttestationCreated(
                msg.sender,
                attestation.about,
                attestation.key,
                attestation.val
            );
        }
    }
}

/// @notice allows sender to set the attestation requirements for new owners. Allows them to update URIs too
contract AttestSendLock is ModuleBase {
    // mapping(address(this) => mapping(senderAddress => mapping(recipAddress => amountBytes))) public creditAttestations;
    // mapping(attestingAddress => mapping(aboutAddress => mapping(key => valueBytes))) public creditAttestations;
    struct Gate {
        address attSource;
        bytes32 key;
        uint256 index;
        bytes32 expectedVal;
    }

    AttestationStation public AT_STAT;
    mapping(uint256 => Gate) public attestGates;
    mapping(uint256 => bytes) public tokenURIs;

    function _onlyAttestation(
        address about,
        address attester,
        bytes32 key,
        uint256 index,
        bytes32 expectedVal
    ) internal view {
        require(
            AT_STAT.attestations(attester, about, key)[index] == expectedVal,
            "Not attested"
        );
    }

    modifier onlyAttested(address about, uint256 cheqId) {
        _onlyAttestation(
            attestGates[cheqId].attSource,
            about,
            attestGates[cheqId].key,
            attestGates[cheqId].index,
            attestGates[cheqId].expectedVal
        );
        _;
    }

    constructor(
        address registrar,
        DataTypes.WTFCFees memory _fees,
        string memory __baseURI
    ) ModuleBase(registrar, _fees) {
        _URI = __baseURI;
    }

    function processWrite(
        address caller,
        address owner,
        uint256 cheqId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        require(
            owner != address(0) && caller != owner,
            "Address zero or self-own"
        );

        (
            address attSource,
            bytes32 key,
            uint256 index,
            bytes32 expectedVal,
            address dappOperator
        ) = abi.decode(initData, (address, bytes32, uint256, bytes32, address));

        _onlyAttestation(attSource, owner, key, index, expectedVal);

        attestGates[cheqId].attSource = attSource;
        attestGates[cheqId].key = key;
        attestGates[cheqId].index = index;
        attestGates[cheqId].expectedVal = expectedVal;

        return takeReturnFee(currency, escrowed + instant, dappOperator, 0);
    }

    function processTransfer(
        address /*caller*/,
        address /*approved*/,
        address /*owner*/,
        address /*from*/,
        address to,
        uint256 cheqId,
        address /*currency*/,
        uint256 escrowed,
        uint256 /*createdAt*/,
        bytes memory /*data*/
    )
        external
        view
        override
        onlyRegistrar
        onlyAttested(to, cheqId)
        returns (uint256)
    {
        // return takeReturnFee(currency, escrowed, dappOperator);
        return 0;
    }

    function processFund(
        address caller,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        require(caller == owner, "Not owner");
        return
            takeReturnFee(
                cheq.currency,
                amount + instant,
                abi.decode(initData, (address)),
                2
            );
    }

    function processCash(
        address /*caller*/,
        address /*owner*/,
        address /*to*/,
        uint256 amount,
        uint256 /*cheqId*/,
        DataTypes.Cheq calldata cheq,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        return
            takeReturnFee(
                cheq.currency,
                amount,
                abi.decode(initData, (address)),
                3
            );
    }

    function processApproval(
        address /*caller*/,
        address /*owner*/,
        address /*to*/,
        uint256 /*cheqId*/,
        DataTypes.Cheq calldata /*cheq*/,
        bytes memory /*initData*/
    ) external view override onlyRegistrar {}

    function processTokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (tokenURIs[tokenId].length == 0) {
            return string(abi.encodePacked(_URI, tokenId));
        } else {
            return string(tokenURIs[tokenId]);
        }
    }

    function updateURI(uint256 cheqId, bytes calldata newURI) public {
        require(msg.sender == ERC721(REGISTRAR).ownerOf(cheqId), "Only Owner");
        tokenURIs[cheqId] = newURI;
    }
}
