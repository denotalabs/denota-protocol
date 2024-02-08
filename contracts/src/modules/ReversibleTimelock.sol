// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import "openzeppelin/utils/Strings.sol";

// ReversibleByBeforeDate
contract ReversibleTimelock is ModuleBase {
    struct Payment {
        address sender;
        address inspector;
        uint256 inspectionEnd;
        string external_url;
        string imageURI;
    }
    mapping(uint256 => Payment) public payments;

    event PaymentCreated(uint256 indexed notaId, address indexed payer, address indexed inspector, uint256 inspectionEnd, string external_url, string imageURI);

    error AddressZero();
    error Disallowed();
    error InspectionEndPassed();

    constructor(
        address registrar
    ) ModuleBase(registrar) {
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
            address inspector,
            uint256 inspectionEnd,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(initData, (address, uint256, string, string));
        
        if (inspector == address(0)) revert AddressZero();
        if (inspectionEnd < block.timestamp) revert InspectionEndPassed();

        payments[notaId] = Payment(caller, inspector, inspectionEnd, external_url, imageURI);

        emit PaymentCreated(notaId, caller, inspector, inspectionEnd, external_url, imageURI);
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
        bytes memory data
    ) external override onlyRegistrar returns (uint256) {
        return 0;
    }

    function processFund(
        address, // caller,
        address, // owner,
        uint256, // amount,
        uint256, // instant,
        uint256, // notaId,
        Nota calldata, // nota,
        bytes calldata // initData
    ) external override onlyRegistrar returns (uint256) {
        revert Disallowed();
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

        if (payment.inspectionEnd > block.timestamp) {  // Current time is before inspection end
            require(caller == payment.inspector, "OnlyByInspector");
            require(to == payment.sender, "OnlyToSender");
        } else {
            require(to == owner, "OnlyToOwner");
        }
        return 0;
    }

    function processApproval(
        address caller,
        address owner,
        address to,
        uint256 notaId,
        Nota calldata nota
    ) external override onlyRegistrar {}

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payments[tokenId];

        return (
                string(
                    abi.encodePacked(
                        ',{"trait_type":"Inspector","value":"',
                        Strings.toHexString(payment.inspector),
                        '"},{"trait_type":"Payer","value":"',
                        Strings.toHexString(payment.sender),
                        '"},{"trait_type":"Inspection End","value":"',
                        Strings.toString(payment.inspectionEnd),
                        '"}'
                    )
                ), 
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        payment.imageURI, 
                        '","name":"Reversible Timelock Nota #',
                        Strings.toHexString(tokenId),
                        '","external_url":"', 
                        payment.external_url,
                        '","description":"Allows the payer to choose the inspector who is then allowed to release the escrow to the owner. After the inspection end date, the owner can release the escrow to themselves."'
                    )
                )
            );
    }
}
