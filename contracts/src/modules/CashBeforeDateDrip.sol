// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {ModuleBase} from "../ModuleBase.sol";


contract CashBeforeDateDrip is ModuleBase {
    struct Payment {
        uint256 expirationDate; // Final date to cash
        uint256 lastCashed; // Last date when cashed
        uint256 dripAmount; // Amount available to cash each period
        uint256 dripPeriod; // Period after which cashing is allowed again
        address sender; // Sender of the payment
        string external_url;
        string imageURI;
    }

    mapping(uint256 notaId => Payment payment) public payments;

    error TooEarly();
    error Expired();
    error Disallowed();
    error OnlyToOwner();
    error ExceedsDripAmount();

    event PaymentCreated(uint256 indexed notaId, address indexed sender, uint256 cashBy, uint256 dripAmount, uint256 dripPeriod, string external_url, string imageURI);
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
            uint256 expirationDate,
            uint256 dripAmount,
            uint256 dripPeriod,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(writeData, (uint256, uint256, uint256, string, string));
        
        payments[notaId] = Payment(expirationDate, block.timestamp, dripAmount, dripPeriod, caller, external_url, imageURI);

        emit PaymentCreated(notaId, caller, expirationDate, dripAmount, dripPeriod, external_url, imageURI);
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
        uint256 amount,
        uint256 notaId,
        Nota calldata /*nota*/,
        bytes calldata /*cashData*/
    ) external override onlyRegistrar returns (uint256) {
        Payment storage payment = payments[notaId];
        if (to == payment.sender){
            require(block.timestamp > payment.expirationDate, "NotExpired");
            return 0;
        }
        if (to != owner) revert OnlyToOwner();
        if (block.timestamp > payment.expirationDate) revert Expired();
        if (block.timestamp < payment.lastCashed + payment.dripPeriod) revert TooEarly();
        if (amount > payment.dripAmount) revert ExceedsDripAmount();

        payment.lastCashed = block.timestamp;
        
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
                        '"},{"trait_type":"Expiration Date","display_type":"date","value":"',
                        Strings.toString(payment.expirationDate),
                        '"},{"trait_type":"Last Cashed","display_type":"date","value":"',
                        Strings.toString(payment.lastCashed),
                        '"},{"trait_type":"Drip Amount","value":"',
                        Strings.toString(payment.dripAmount),
                        '"},{"trait_type":"Drip Period","value":"',
                        Strings.toString(payment.dripPeriod),  // Question: Should this be a datetime?
                        '"}'
                    )
                ),
                string(
                    abi.encodePacked(
                        ',"image":"', 
                        payment.imageURI, 
                        '","name":"Cash Before Date Drip Nota #',
                        Strings.toHexString(tokenId),
                        '","external_url":"', 
                        payment.external_url,
                        '","description":"Allows the owner to claim the drip amount once every drip period. If the expiration date is exceeded the sender can take back the remaining tokens."'
                    )
                )
            );
    }
}
