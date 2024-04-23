// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import {IHats} from "hats-protocol/interfaces/IHats.sol";
import "openzeppelin/utils/Strings.sol";

contract HatsReversibleRelease is ModuleBase {
    IHats public immutable HATS;

    struct Payment {
        uint256 hatId;
        address payer;
        string external_url;
        string imageURI;
    }

    mapping(uint256 notaId => Payment payment) public payments;

    event PaymentCreated(uint256 indexed notaId, address indexed payer, uint256 hatId, string external_url, string imageURI);
    error OnlyOwner();
    error Disallowed();
    error AddressZero();
    error Unauthorized();

    constructor(address registrar, address _hatContract) ModuleBase(registrar) {
        HATS = IHats(_hatContract);
    }

    function processWrite(
        address caller,
        address /*owner*/,
        uint256 notaId,
        address /*currency*/,
        uint256 /*escrowed*/,
        uint256 /*instant*/,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        (
            uint256 hatId,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                initData,
                (uint256, string, string)
            );
        
        // Use maxSupply instead?
        if (HATS.hatSupply(hatId) == 0) revert Disallowed();

        payments[notaId] = Payment(hatId, caller, external_url, imageURI);

        emit PaymentCreated(notaId, caller, hatId, external_url, imageURI);
        return 0;
    }

    function processFund(
        address /*caller*/,
        address /*owner*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/,
        bytes calldata /*initData*/
    ) external override onlyRegistrar returns (uint256) {
        return 0;
    }

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 /*amount*/,
        uint256 notaId,
        Nota calldata /*nota*/,
        bytes calldata /*initData*/
    ) external override onlyRegistrar returns (uint256) {
        Payment memory payment = payments[notaId];

        if (!HATS.isWearerOfHat(caller, payment.hatId)) revert Unauthorized();
        require(to == owner || to == payment.payer, "ONLY_TO_OWNER_OR_SENDER");
        return 0;
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payments[tokenId];

        return (
                string(
                    abi.encodePacked(
                        ',{"trait_type":"Hat ID","value":"',
                        Strings.toHexString(payment.hatId),
                        '"},{"trait_type":"Payer","value":"',
                        Strings.toHexString(payment.payer),
                        '"}'
                    )
                ), 
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        payment.imageURI, 
                        '","name":"Hat Controlled Nota #',
                        Strings.toHexString(tokenId),
                        '","external_url":"', 
                        payment.external_url,
                        '","description":"This Nota is controlled by a Hat user which is allowed to return funds to the sender or release them."'
                    )
                )
            );
    }
}
