// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import {DataTypes} from "../libraries/DataTypes.sol";

library Events {
    // emit cheq structs or each variable?
    // event ModuleGlobalsGovernanceSet(
    //     address indexed prevGovernance,
    //     address indexed newGovernance,
    //     uint256 timestamp
    // );
    // event ModuleGlobalsTreasurySet(
    //     address indexed prevTreasury,
    //     address indexed newTreasury,
    //     uint256 timestamp
    // );
    // event ModuleGlobalsTreasuryFeeSet(
    //     uint16 indexed prevTreasuryFee,
    //     uint16 indexed newTreasuryFee,
    //     uint256 timestamp
    // );
    // // event FeeModuleBaseConstructed(address indexed moduleGlobals, uint256 timestamp);
    // event ModuleBaseConstructed(address indexed registrar, uint256 timestamp);
    // Question: emit the module address or bytehash?
    event ModuleWhitelisted(
        address indexed user,
        address indexed module,
        bool isAccepted,
        bool isClonable,
        string moduleName,
        uint256 timestamp
    );
    event TokenWhitelisted(
        address caller,
        address indexed token,
        bool indexed accepted,
        string tokenName,
        uint256 timestamp
    );

    event Written(
        address indexed caller,
        uint256 cheqId,
        address indexed owner, // Question is this needed considering ERC721 _mint() emits owner `from` address(0) `to` owner?
        uint256 instant,
        address currency,
        uint256 escrowed,
        uint256 createdAt,
        uint256 moduleFee,
        address indexed module,
        bytes moduleData
    );
    // Not used
    event Transferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 moduleFee,
        uint256 timestamp
    );
    event Funded(
        address indexed funder,
        uint256 indexed cheqId,
        uint256 amount,
        uint256 instant,
        bytes indexed fundData,
        uint256 moduleFee,
        uint256 timestamp
    );
    event Cashed(
        address indexed casher,
        uint256 indexed cheqId,
        address to,
        uint256 amount,
        bytes indexed cashData,
        uint256 moduleFee,
        uint256 timestamp
    );
}
