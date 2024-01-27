// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {INotaModule} from "../interfaces/INotaModule.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";

/**
 * @notice A simple time release module
 * Escrowed tokens are cashable after the releaseDate
 */
contract SimpleTimelock is ModuleBase {
    struct Timelock {
        uint256 releaseDate;
        string external_url;
        string imageURI;
    }

    mapping(uint256 => Timelock) public timelocks;

    event TimelockCreated(uint256 notaId, uint256 _releaseDate, string external_url, string imageURI);
    error OnlyOwnerOrApproved();

    constructor(
        address registrar
    ) ModuleBase(registrar) {
    }

    function processWrite(
        address /*caller*/,
        address /*owner*/,
        uint256 notaId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata writeData
    ) external override onlyRegistrar returns (uint256) {
        (   uint256 _releaseDate,
            string memory external_url,
            string memory imageURI
        ) = abi.decode(
                writeData,
                (uint256, string, string)
            );

        timelocks[notaId] = Timelock(_releaseDate, external_url, imageURI);

        emit TimelockCreated(notaId, _releaseDate, external_url, imageURI);
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
    ) external view override onlyRegistrar returns (uint256) {
        require(false, "Only sending and cashing");
        return 0;
    }

    function processCash(
        address /*caller*/,
        address owner,
        address to,
        uint256 amount,
        uint256 notaId,
        Nota calldata nota,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        require(to == owner, "Only cashable to owner");
        require(amount == nota.escrowed, "Must fully cash");
        require(timelocks[notaId].releaseDate < block.timestamp, "TIMELOCK");
        return 0;
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/
    ) external view override onlyRegistrar {
        require(caller == owner, "Only owner can approve");
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        return ("", string(abi.encodePacked(',"external_url":', tokenId)));
    }
}

/**
 * @notice A simple time release module. The longer the release time, the more in fees you have to pay
 * Escrowed tokens are cashable after the releaseDate
 * Question: Allow nota creator to update the URI?
 */
contract SimpleTimelockFee is ModuleBase {
    mapping(uint256 => uint256) public releaseDate;

    event Timelock(uint256 notaId, uint256 _releaseDate);
    error OnlyOwnerOrApproved();

    constructor(
        address registrar,
        string memory __baseURI
    ) ModuleBase(registrar) {
        // _URI = __baseURI;
    }

    function processWrite(
        address /*caller*/,
        address /*owner*/,
        uint256 notaId,
        address /*currency*/,
        uint256 /*escrowed*/,
        uint256 /*instant*/,
        bytes calldata initData
    ) external override onlyRegistrar returns (uint256) {
        (uint256 _releaseDate) = abi.decode(initData, (uint256)); // Frontend uploads (encrypted) memo document and the URI is linked to notaId here (URI and content hash are set as the same)
        releaseDate[notaId] = _releaseDate;
        emit Timelock(notaId, _releaseDate);
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
    ) external view override onlyRegistrar returns (uint256) {
        require(false, "Only sending and cashing");
        return 0;
    }

    function processCash(
        address /*caller*/,
        address /*owner*/,
        address /*to*/,
        uint256 amount,
        uint256 /*notaId*/,
        Nota calldata nota,
        bytes calldata /*initData*/
    ) external override onlyRegistrar returns (uint256) {
        require(amount == nota.escrowed, "Must fully cash");
        return 0;
    }

    function processApproval(
        address caller,
        address owner,
        address /*to*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/
    ) external view override onlyRegistrar {
        require(caller == owner, "Only owner can approve");
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {
        return ("", "");
    }
}

