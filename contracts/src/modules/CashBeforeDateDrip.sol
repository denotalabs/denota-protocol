// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "openzeppelin/utils/Strings.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {ModuleBase} from "../ModuleBase.sol";

/* 
commit: https://github.com/denotalabs/denota-protocol/commit/678ce39e0280fe4305b12d4efe0e0d97a3486216: 0x00000000CcE992072E23cda23A1986f2207f5e80
commit: https://github.com/denotalabs/denota-protocol/commit/c428c34102ffa91c0d8819db47088ddb6ac68108: 0x00000000e8c13602e4d483a90af69e7582a43373
*/
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
    error ExpirationDatePassed();
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
        
        if (expirationDate <= block.timestamp) revert ExpirationDatePassed();
        
        payments[notaId] = Payment(expirationDate, 0, dripAmount, dripPeriod, caller, external_url, imageURI);

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

    function _appendTimeUnit(string memory current, uint256 time, uint256 unit, string memory unitName) private pure returns (string memory) {
        uint256 unitCount = time / unit;
        if (unitCount > 0) {
            return string(abi.encodePacked(current, bytes(current).length > 0 ? " " : "", Strings.toString(unitCount), unitName));
        }
        return current;
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payments[tokenId];

        string memory dripPeriod = "";
        uint256 remainingTime = payment.dripPeriod;
        if (remainingTime >= 365 days) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 365 days, " year(s)");
            remainingTime %= 365 days;
        }
        if (remainingTime >= 30 days) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 30 days, " month(s)");
            remainingTime %= 30 days;
        }
        if (remainingTime >= 1 days) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 1 days, " day(s)");
            remainingTime %= 1 days;
        }
        if (remainingTime >= 1 hours) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 1 hours, " hour(s)");
            remainingTime %= 1 hours;
        }
        if (remainingTime >= 1 minutes) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 1 minutes, " minute(s)");
            remainingTime %= 1 minutes;
        }
        if (remainingTime >= 1 seconds) {
            dripPeriod = _appendTimeUnit(dripPeriod, remainingTime, 1 seconds, " second(s)");
        }

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
                        dripPeriod,
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
