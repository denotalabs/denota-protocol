"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.contractMappingForChainId = exports.ContractAddressMapping = void 0;
exports.ContractAddressMapping = {
    mumbai: {
        CheqBase64Encoding: "0xe615b37696Eb4C2c1ca22375D69847d1607325D9",
        DataTypes: "0x8E9FC639Aa68924b9e39f9A19c6abDa18896C249",
        Errors: "0xD10b482e09160C33eea09ce976b88caD5CD7032e",
        Events: "0xBb8c2Bc5e5AEDC4AB652c551D418980013FA76e7",
        registrar: "0xF85D83258CD1D8beb5998439C73C11a6b820d6B9",
        directPay: "0x9e59aCBB489599D4Fd1D3EbbFb5320f918F50F19",
        dai: "0xc5B6c09dc6595Eb949739f7Cd6A8d542C2aabF4b",
        weth: "0xe37F99b03C7B4f4d71eE20e8eF3AC4E138D47F80",
    },
    alfajores: {
        CheqBase64Encoding: "0x66f90099f96143d58e2Ed2fD306006439731197E",
        DataTypes: "0xB0420096BF61Bd79A37108aA7e1F654A7c4a5f2b",
        Errors: "0xa9f0CE52c8De7496F7137cF807A6D33df06C2C87",
        Events: "0x8296aEc2E9Ad887B8a47980Db2Fa4F675F011567",
        registrar: "0x41a3D11eC4dE4eaa3A6b0fD584693F86fB85E0EB",
        directPay: "0x6Cf359a427Fd90BcDD53FcB4A0518C3fb72529b0",
        dai: "0xe314158969CCa87E88350196308f96D879D18b83",
        weth: "0x722D4CED724b69A416AfA50860cEd7B71a1bf689",
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
