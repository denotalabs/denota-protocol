// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {ModuleBase} from "../ModuleBase.sol";


// Can be used to incentivize NFT purchases, like a coupon
contract BalanceOfConditionalCash is ModuleBase {
    enum ConditionType {
        LT,
        GT,
        EQ,
        LTEQ,
        GTEQ
    }

    struct Condition {
        IERC721 NFTAddress;
        ConditionType conditionType;
        address sender;
        uint96 expirationDate;
        uint256 threshold;
        string external_url;
        string imageURI;
    }

    mapping(uint256 => Condition) public conditions;

    error ConditionFailed(uint256 threshold, uint256 value);
    error Disallowed();
    error TransferBeforeCash();

    event ConditionCreated(
        IERC721 indexed NFTAddress,
        ConditionType indexed conditionType,
        uint96 expiry,
        uint256 indexed threshold,
        string external_url,
        string imageURI
    );

    constructor(address registrar) ModuleBase(registrar) {
    }

    function processWrite(
        address caller,
        address /*owner*/,
        uint256 notaId,
        address /*currency*/,
        uint256 /*escrowed*/,
        uint256 /*instant*/,
        bytes calldata writeData
    ) external virtual override onlyRegistrar returns (uint256) {
        (
            IERC721 NFTAddress,
            ConditionType conditionType,
            uint96 expirationDate,
            uint256 threshold,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                writeData,
                (IERC721, ConditionType, uint96, uint256, string, string)
            );

        conditions[notaId] = Condition(NFTAddress, conditionType, caller, expirationDate, threshold, external_url, imageURI);

        emit ConditionCreated(NFTAddress, conditionType, expirationDate, threshold, external_url, imageURI);

        return 0;
    }

    function processTransfer(
        address /*caller*/,
        address /*approved*/,
        address /*owner*/,
        address /*from*/,
        address /*to*/,
        uint256 /*notaId*/,
        Nota calldata nota,
        bytes calldata /*transferData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        if (nota.escrowed > 0) revert TransferBeforeCash();  // Don't allow circumventing of the condition

        return 0;
    }

    function processCash(
        address /*caller*/,
        address owner,
        address to,
        uint256 /*amount*/,
        uint256 notaId,
        Nota calldata /*nota*/,
        bytes calldata /*cashData*/
    ) external virtual override onlyRegistrar returns (uint256) {

        Condition memory condition = conditions[notaId];
        
        if (block.timestamp > uint256(condition.expirationDate)) { // Expired
            if (to != condition.sender) revert Disallowed();  // Must go back to sender
            return 0;
        } else {
            if (to != owner) revert Disallowed();  // Must go to owner
        }

        uint256 value = condition.NFTAddress.balanceOf(owner);

        if (
            (condition.conditionType == ConditionType.LT && value < condition.threshold) ||
            (condition.conditionType == ConditionType.GT && value > condition.threshold) ||
            (condition.conditionType == ConditionType.EQ && value == condition.threshold) ||
            (condition.conditionType == ConditionType.LTEQ && value <= condition.threshold) ||
            (condition.conditionType == ConditionType.GTEQ && value >= condition.threshold)
        ) {
            return 0;
        }
        revert ConditionFailed(condition.threshold, value);
    }

    function processFund(
        address /*caller*/,
        address /*owner*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        uint256 /*notaId*/,
        Nota calldata nota,
        bytes calldata /*fundData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        if (nota.escrowed == 0) revert Disallowed();
        return 0;
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Condition memory condition = conditions[tokenId];

        string memory conditionType;
        if (condition.conditionType == ConditionType.LT) {
            conditionType = "Less Than";
        } else if (condition.conditionType == ConditionType.GT) {
            conditionType = "Greater Than";
        } else if (condition.conditionType == ConditionType.EQ) {
            conditionType = "Equal To";
        } else if (condition.conditionType == ConditionType.LTEQ) {
            conditionType = "Less Than or Equal To";
        } else if (condition.conditionType == ConditionType.GTEQ) {
            conditionType = "Greater Than or Equal To";
        }

        return (
                string(
                    abi.encodePacked(
                        ',{"trait_type":"NFT Address","value":"',
                        Strings.toHexString(address(condition.NFTAddress)),
                        '"},{"trait_type":"Condition Type","value":"',
                        conditionType,
                        '"},{"trait_type":"Sender","value":"',
                        Strings.toHexString(condition.sender),
                        '"},{"trait_type":"Expiration Date","display_type":"date","value":"',
                        Strings.toString(condition.expirationDate),
                        '"},{"trait_type":"Threshold Number","value":"',
                        Strings.toString(condition.threshold),
                        '"}'
                    )
                ), 
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        condition.imageURI, 
                        '","name":"Balance Of NFTs Nota #',
                        Strings.toHexString(tokenId),
                        '","external_url":"', 
                        condition.external_url,
                        '","description":"Payment release is controlled by the whether the owner has the correct balance of NFTs from a specified collection. If the expiration date is reached, the payment can be returned to the sender."'
                    )
                )
            );
    }
}