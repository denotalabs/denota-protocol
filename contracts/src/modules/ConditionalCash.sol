// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {ModuleBase} from "../ModuleBase.sol";

// Allow notas to specify each or have a redeployable hook for a specific address+condition?
contract BoolConditionalCash is ModuleBase {
    struct Condition {
        address conditionAddress;
        bytes4 conditionSelector;
        string external_url;
        string imageURI;
    }

    mapping(uint256 => Condition) public conditions;

    error ConditionFailed();
    event ConditionCreated(
        address conditionAddress,
        bytes4 conditionSelector,
        string external_url,
        string imageURI
    );

    constructor(address registrar) ModuleBase(registrar) {
    }

    function processWrite(
        address /*caller*/,
        address /*owner*/,
        uint256 notaId,
        address /*currency*/,
        uint256 /*escrowed*/,
        uint256 /*instant*/,
        bytes calldata writeData
    ) external virtual override onlyRegistrar returns (uint256) {
        (
            address conditionAddress,
            bytes4 conditionSelector,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                writeData,
                (address, bytes4, string, string)
            );

        conditions[notaId] = Condition(conditionAddress, conditionSelector, external_url, imageURI);

        emit ConditionCreated(conditionAddress, conditionSelector, external_url, imageURI);

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
        if (to != owner) revert();

        Condition memory condition = conditions[notaId];
        (bool success, ) = condition.conditionAddress.staticcall(abi.encodeWithSelector(condition.conditionSelector));
        if (success) {
            return 0;
        }
        revert ConditionFailed();
    }

    function processFund(
        address /*caller*/,
        address /*owner*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/,
        bytes calldata /*fundData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        revert();
    }
}
contract GTConditionalCash is ModuleBase {
    struct Condition {
        address conditionAddress;
        bytes4 conditionSelector;
        uint256 threshold;
        string external_url;
        string imageURI;
    }

    mapping(uint256 => Condition) public conditions;

    error ConditionFailed();
    event ConditionCreated(
        address conditionAddress,
        uint256 threshold,
        bytes4 conditionSelector,
        string external_url,
        string imageURI
    );

    constructor(address registrar) ModuleBase(registrar) {
    }

    function processWrite(
        address /*caller*/,
        address /*owner*/,
        uint256 notaId,
        address /*currency*/,
        uint256 /*escrowed*/,
        uint256 /*instant*/,
        bytes calldata writeData
    ) external override onlyRegistrar returns (uint256) {
        (
            address conditionAddress,
            bytes4 conditionSelector,
            uint256 threshold,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                writeData,
                (address, bytes4, uint256, string, string)
            );

        conditions[notaId] = Condition(conditionAddress, conditionSelector, threshold, external_url, imageURI);

        emit ConditionCreated(conditionAddress, threshold, conditionSelector, external_url, imageURI);
        
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
    ) external override onlyRegistrar returns (uint256) {
        if (to != owner) revert();

        Condition memory condition = conditions[notaId];
        (bool success , bytes memory data) = condition.conditionAddress.staticcall(abi.encodeWithSelector(condition.conditionSelector));
        require(success, "Call_failed");

        uint256 number = abi.decode(data, (uint256));
        if (number > condition.threshold) {
            return 0;
        }
        revert ConditionFailed();
    }

    function processFund(
        address /*caller*/,
        address /*owner*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/,
        bytes calldata /*fundData*/
    ) external override onlyRegistrar returns (uint256) {
        revert();
    }
}

contract GTConditionalTimeCash is ModuleBase {
    struct Condition {
        address originalSender;
        address conditionAddress;
        bytes4 conditionSelector;
        uint256 threshold;
        uint256 expiration;
        string external_url;
        string imageURI;
    }

    mapping(uint256 => Condition) public conditions;

    error ConditionFailed();
    error OnlyToOwner();
    error Disallowed();
    error Expired();

    event ConditionCreated(
        uint256 indexed notaId, 
        address indexed originalSender,
        address indexed conditionAddress, 
        bytes4 conditionSelector, 
        uint256 threshold,
        uint256 expiration, 
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
    ) external override onlyRegistrar returns (uint256) {
        (
            address conditionAddress,
            bytes4 conditionSelector,
            uint256 threshold,
            uint256 expiration,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                writeData,
                (address, bytes4, uint256, uint256, string, string)
            );

        conditions[notaId] = Condition(caller, conditionAddress, conditionSelector, threshold, expiration, external_url, imageURI);

        emit ConditionCreated(notaId, caller, conditionAddress, conditionSelector, threshold, expiration, external_url, imageURI);
        
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
    ) external override onlyRegistrar returns (uint256) {
        Condition memory condition = conditions[notaId];

        if (block.timestamp > condition.expiration) {
            require(to == condition.originalSender, "Only To Original Sender");
            return 0;
        }

        if (to != owner) revert OnlyToOwner();
        
        (bool success, bytes memory data) = condition.conditionAddress.staticcall(
            abi.encodeWithSelector(condition.conditionSelector)
        );
        uint256 result = abi.decode(data, (uint256));

        if (success && result > condition.threshold) {
            return 0;
        } else {
            revert ConditionFailed();
        }
    }


    function processFund(
        address /*caller*/,
        address /*owner*/,
        uint256 /*amount*/,
        uint256 /*instant*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/,
        bytes calldata /*fundData*/
    ) external override onlyRegistrar returns (uint256) {
        revert Disallowed();
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Condition memory condition = conditions[tokenId];

        return (
                string(
                    abi.encodePacked(
                        ',{"trait_type":"Original Sender","value":"',
                        Strings.toHexString(condition.originalSender),
                        '"},{"trait_type":"Conditional Contract Address","value":"',
                        Strings.toHexString(condition.conditionAddress),
                        '"},{"trait_type":"Contract Function","value":"',
                        Strings.toHexString(uint32(condition.conditionSelector)),
                        '"},{"trait_type":"Threshold Number","value":"',
                        Strings.toHexString(condition.threshold),
                        '"},{"trait_type":"Expiration Date","value":"',
                        Strings.toHexString(condition.expiration),
                        '"}'
                    )
                ), 
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        condition.imageURI, 
                        '","name":"Conditional Release Nota #',
                        Strings.toHexString(tokenId),
                        '","external_url":"', 
                        condition.external_url,
                        '","description":"The Conditional Release hook allows minters to send Notas that can only be cashed if the specified threshold is greater than the specified smart contract variable. The owner has until the threshold time this opportunity after which the sender can claw back the funds."'
                    )
                )
            );
    }

}