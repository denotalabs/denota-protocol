"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.contractMappingForChainId = exports.ContractAddressMapping = void 0;
exports.ContractAddressMapping = {
    mumbai: {
        DataTypes: "0x4287f38FecFC24Bd80F643f682E727bD6407F484",
        Errors: "0x2418EF1Dab6A0Db2F05ea0A03221d19708388F26",
        Events: "0x0faCA1284C7D037120D5D7C66Cd655B777c8807D",
        registrar: "0x50d535af78A154a493d6ed466B363DDeBE4Ee88f",
        escrow: "0x361034E527Ce50Ae24DFaCb50C056CBd3C3b31da",
        directPay: "0x6396CB807Aa9cAd7DdDCFf8dE153E3F3Dcad6D45",
        dai: "0xc5B6c09dc6595Eb949739f7Cd6A8d542C2aabF4b",
        weth: "0xe37F99b03C7B4f4d71eE20e8eF3AC4E138D47F80",
        milestones: "",
    },
    alfajores: {
        DataTypes: "0xF55e1Ba563B1FF60BAd3d5995F04c1c6a4Be98A5",
        Errors: "0x42c8c5E13f66C7a1e7336dFa86adE0e1C8d15f2b",
        Events: "0x8CAB9d27414f7043Eb4FBD953835FFd5C532773E",
        registrar: "0x5f7804628849d5B34bbA0e6d21c572FC991E3Fec",
        directPay: "0xf14Cf88b8B41B3CBCDf7564054870B0AA43bb6e3",
        escrow: "0x8EF1c8CFf1E2701A359Da1205135A0f39D13382a",
        dai: "0xe314158969CCa87E88350196308f96D879D18b83",
        weth: "0x722D4CED724b69A416AfA50860cEd7B71a1bf689",
        milestones: "",
    },
};
var contractMappingForChainId = function (chainId) {
    switch (chainId) {
        case 80001:
            return exports.ContractAddressMapping.mumbai;
        case 44787:
            return exports.ContractAddressMapping.alfajores;
        default:
            return undefined;
    }
};
exports.contractMappingForChainId = contractMappingForChainId;
