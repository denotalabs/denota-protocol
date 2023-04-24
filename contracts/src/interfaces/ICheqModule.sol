// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {DataTypes} from "../libraries/DataTypes.sol";

// Question: Should the require statements be part of the interface? Would allow people to query canWrite(), canCash(), etc
// Question: Should module return their fee in BPS or actual fee amount?
interface ICheqModule {
    function processWrite(
        address caller,
        address owner,
        uint256 cheqId,
        address currency,
        uint256 escrowed,
        uint256 instant,
        bytes calldata initData
    ) external returns (uint256);

    // QUESTION: return (moduleFee, adjOwner, adjCheq)?

    function processTransfer(
        address caller,
        address approved,
        address owner,
        address from,
        address to,
        uint256 cheqId,
        address currency,
        uint256 escrowed,
        uint256 createdAt,
        bytes calldata data
    ) external returns (uint256);

    // QUESTION: return (adjOwner, adjCheq)?

    function processFund(
        address caller,
        address owner,
        uint256 amount,
        uint256 instant,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata initData
    ) external returns (uint256);

    // QUESTION: return (adjOwner, adjAmount, adjCheq)?

    function processCash(
        address caller,
        address owner,
        address to,
        uint256 amount,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes calldata initData
    ) external returns (uint256);

    // QUESTION: return (adjOwner, adjTo, adjAmount, adjCheq)?

    function processApproval(
        address caller,
        address owner,
        address to,
        uint256 cheqId,
        DataTypes.Cheq calldata cheq,
        bytes memory initData
    ) external;

    // QUESTION: return (adjOwner, adjCheq)?

    // function processOwnerOf(address owner, uint256 tokenId) external view returns(bool); // TODO settle on what this returns
    // function processBalanceOf() external view returns(uint256);
    function processTokenURI(
        uint256 tokenId
    ) external view returns (string memory); // TODO how to format IPFS payloads to insert into the metadata
}
