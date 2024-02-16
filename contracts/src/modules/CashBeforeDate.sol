// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {ModuleBase} from "../ModuleBase.sol";


contract CashBeforeDate is ModuleBase {
    struct Payment {
        uint256 cashBy;
        address sender;
        string external_url;
        string imageURI;
    }
    mapping(uint256 notaId => Payment payment) public payments;

    error Disallowed();
    event PaymentCreated(uint256 indexed notaId, address indexed sender, uint256 cashBy, string external_url, string imageURI);
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
            uint256 cashBy,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                writeData,
                (uint256, string, string)
        );
        
        payments[notaId] = Payment(cashBy, caller, external_url, imageURI);

        emit PaymentCreated(notaId, caller, cashBy, external_url, imageURI);

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
        revert Disallowed();
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
        Payment memory payment = payments[notaId];

        if (block.timestamp > payment.cashBy) { // Expired
            require(to == payment.sender, "OnlyToSender");
        } else {  // Claimable
            require(to == owner, "OnlyToOwner");
        }
        return 0;
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payments[tokenId];

        return (
                string(
                    abi.encodePacked(
                        ',{"trait_type":"Sender","value":"',
                        Strings.toHexString(payment.sender),
                        '"},{"trait_type":"Cash By Date","display_type":"date","value":"',
                        Strings.toString(payment.cashBy),
                        '"}'
                    )
                ),
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        payment.imageURI, 
                        '","name":"Cash Before Date Nota #',
                        Strings.toHexString(tokenId),
                        '","external_url":"', 
                        payment.external_url,
                        '","description":"Allows the owner to claim the tokens before the expiry date, otherwise the sender can take them back."'
                    )
                )
            );
    }
}