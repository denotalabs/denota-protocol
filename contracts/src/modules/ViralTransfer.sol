// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.14;

import {ModuleBase} from "../ModuleBase.sol";
import {Nota} from "../libraries/DataTypes.sol";
import {INotaRegistrar} from "../interfaces/INotaRegistrar.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/utils/Strings.sol";

contract ViralTransfer is ModuleBase {
    IERC721 public immutable GITCOIN_PASSPORT;

    struct Viral {
        uint256 availableShares; // Each nota only has 100 shares
        string imageURI;
        mapping(address => bool) previousOwner;
        mapping(address => uint256) addressShares;
    }
    
    error OnlyOwnerOrApproved();

    mapping(uint256 => Viral) public viralTransfers;

    constructor(address registrar, IERC721 gitcoinPassport) ModuleBase(registrar) {
        GITCOIN_PASSPORT = gitcoinPassport;
    }

    function shareDecay(uint256 shares) public pure returns (uint256) {
        // if shares > 50 return 20;
        return shares / 2;
    }

    function processWrite(
        address caller,
        address owner,
        uint256 notaId,
        address /*currency*/,
        uint256 /*escrowed*/,
        uint256 /*instant*/,
        bytes calldata writeData
    ) external override onlyRegistrar returns (uint256) {
        require(GITCOIN_PASSPORT.balanceOf(owner) > 0, "Must have a passport"); // Sybil mechanism check
        
        viralTransfers[notaId].imageURI = abi.decode(writeData, (string));
        viralTransfers[notaId].availableShares = 100;
        viralTransfers[notaId].previousOwner[caller] = true;
        viralTransfers[notaId].addressShares[caller] = shareDecay(100);
        return 0;
    }

    function processTransfer(
        address /*caller*/,
        address /*approved*/,
        address owner,
        address from,
        address to,
        uint256 notaId,
        Nota calldata nota,
        bytes calldata /*transferData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        require(GITCOIN_PASSPORT.balanceOf(to) > 0, "Must have a passport"); // Sybil mechanism check
        require(!viralTransfers[notaId].previousOwner[to], "Must not be a previous owner");
        uint256 reward = (nota.escrowed * viralTransfers[notaId].addressShares[owner]) / 100;
        viralTransfers[notaId].availableShares -= viralTransfers[notaId].addressShares[owner];
        viralTransfers[notaId].previousOwner[from] = true;

        INotaRegistrar(REGISTRAR).cash(notaId, reward, to, "");
        return 0;
    }

    function processCash(
        address caller,
        address /*owner*/,
        address /*to*/,
        uint256 /*amount*/,
        uint256 /*notaId*/,
        Nota calldata /*nota*/,
        bytes calldata /*cashData*/
    ) external virtual override onlyRegistrar returns (uint256) {
        require(caller == address(this), "");  // Can only cash by transferring
        return 0;
    }

    function processTokenURI(
        uint256 tokenId
    ) external view override returns (string memory, string memory) {

        string memory attributes = string(
            abi.encodePacked(
                '"},{"trait_type":"AvailableShares","value":"',
                Strings.toHexString(uint256(viralTransfers[tokenId].availableShares)),
                '"},{"trait_type":"Must Have","value":"',
                "Gitcoin Passport",
                '"}'
            )
        );

        return (attributes,
            string(
                abi.encodePacked(
                    ',"external_url":"',
                    abi.encodePacked("TODO DENOTA MARKET MATERIALS"),
                    '","image":"',
                    viralTransfers[tokenId].imageURI, '"'
                )
        ));
    }

}