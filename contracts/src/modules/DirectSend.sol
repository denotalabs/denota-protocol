// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import "openzeppelin/utils/Strings.sol";

/**
 * @notice A simple payment module that includes an IPFS hash for memos (included in the URI)
 */
contract DirectSend is ModuleBase {
    struct Payment {
        uint256 amount;
        string external_url;
        string imageURI;
    }
    mapping(uint256 => Payment) public payInfo;

    error EscrowUnsupported();
    error Disallowed();

    event PaymentCreated(uint256 indexed notaId, uint256 amount, string memoHash, string imageURI);

    constructor(
        address registrar
    ) ModuleBase(registrar) {
    }

    function processWrite(
        address /*caller*/,
        address /*owner*/,
        uint256 notaId,
        address /*currency*/,
        uint256 escrowed,
        uint256 instant,
        bytes calldata initData
    ) public override onlyRegistrar returns (uint256) {
        (
            string memory external_url,
            string memory imageURI
        ) = abi.decode(initData, (string, string));

        if (escrowed != 0) revert EscrowUnsupported();
        
        payInfo[notaId] = Payment(instant, external_url, imageURI);

        emit PaymentCreated(notaId, instant, external_url, imageURI);
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
    ) public override onlyRegistrar returns (uint256) {
        revert Disallowed();
    }

    function processCash(
        address /*caller*/,
        address /*owner*/,
        address /*to*/,
        uint256 /*amount*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/,
        bytes calldata /*initData*/
    ) public view override onlyRegistrar returns (uint256) {
        revert Disallowed();
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        Payment memory payment = payInfo[tokenId];

        return (
            string(abi.encodePacked(
            ',{"trait_type":"Amount","value":"',
            Strings.toString(payment.amount),
            '"}')),
            string(
                abi.encodePacked(
                    ',"external_url":"',
                    payment.external_url,
                    '","name":"Direct Pay Nota #',
                    Strings.toHexString(tokenId),
                    '","image":"',
                    payment.imageURI, 
                    '","description":"Sends an image and a document along with a record of how much was paid."'
                )
        ));
    }
}
