// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {ModuleBase} from "../ModuleBase.sol";


contract SimpleCash is ModuleBase {
    struct Payment {
        string external_url;
        string imageURI;
    }
    mapping(uint256 notaId => Payment payment) public payments;

    error Disallowed();
    event PaymentCreated(uint256 notaId, string external_url, string imageURI);
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
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                writeData,
                (string, string)
            );
        
        payments[notaId] = Payment(external_url, imageURI);

        emit PaymentCreated(notaId, external_url, imageURI);

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
        uint256 /*notaId*/,
        Nota calldata /*nota*/,
        bytes calldata /*cashData*/
    ) external override onlyRegistrar returns (uint256) {
        require(owner == to, "OnlyToOwner");
        return 0;
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payments[tokenId];

        return (
                "", 
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        payment.imageURI, 
                        '","name":"Simple Cash Nota #',
                        Strings.toHexString(tokenId),
                        '","external_url":"', 
                        payment.external_url,
                        '","description":"Enables two-step payments much like a cheque that needs to be cashed by the owner. Documents and an image can be attached as well."'
                    )
                )
            );
    }
}