export const ContractAddressMapping = {
  mumbai: {
    DataTypes: "0x4287f38FecFC24Bd80F643f682E727bD6407F484",
    Errors: "0x2418EF1Dab6A0Db2F05ea0A03221d19708388F26",
    Events: "0x0faCA1284C7D037120D5D7C66Cd655B777c8807D",
    registrar: "0x50d535af78A154a493d6ed466B363DDeBE4Ee88f",
    reversibleRelease: "0x361034E527Ce50Ae24DFaCb50C056CBd3C3b31da",
    directPay: "0x6396CB807Aa9cAd7DdDCFf8dE153E3F3Dcad6D45",
    dai: "0xe37F99b03C7B4f4d71eE20e8eF3AC4E138D47F80",
    weth: "0xc5B6c09dc6595Eb949739f7Cd6A8d542C2aabF4b",
    milestones: "",
    bridgeReceiver: "0x9694c8B653dA034b7E92cA6fd2529C15c556ce06",
    bridgeSender: "0x89A545bC5f783F18F3a0AC3E92c78E03a14CC69c",
    directPayAxelar: "0xed9B684c481F5b20A1f5bEeA5E458d92f7D1b2BC",
    batch: "0xa58AA04c66aF0e8A5B22e17a48EEA34405c526b5",
    usdc: "",
  },
  alfajores: {
    DataTypes: "0xF55e1Ba563B1FF60BAd3d5995F04c1c6a4Be98A5",
    Errors: "0x42c8c5E13f66C7a1e7336dFa86adE0e1C8d15f2b",
    Events: "0x8CAB9d27414f7043Eb4FBD953835FFd5C532773E",
    registrar: "0x000000003C9C54B98C17F5A8B05ADca5B3B041eD",
    directPay: "0xf14Cf88b8B41B3CBCDf7564054870B0AA43bb6e3",
    reversibleRelease: "0x8EF1c8CFf1E2701A359Da1205135A0f39D13382a",
    dai: "0xe314158969CCa87E88350196308f96D879D18b83",
    weth: "0x722D4CED724b69A416AfA50860cEd7B71a1bf689",
    milestones: "",
    bridgeReceiver: "0x21386f75A5809344277b3d1B3ed3Ef0b19496189",
    bridgeSender: "0xFd77Eed331C200B3Ea360Ff172fA849BAE8cb66d",
    directPayAxelar: "0x453ccF56e94B03888bc787b249eb3A4c99d769f7",
    batch: "",
    usdc: "",
  },
  polygon: {
    DataTypes: "",
    Errors: "",
    Events: "",
    registrar: "0x000000003C9C54B98C17F5A8B05ADca5B3B041eD",
    directPay: "0x00000003672153a114583fa78c3d313d4e3cae40",
    reversibleRelease: "0x0000000078E1A913Ee98c64CEc34fe813872eF79",
    dai: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", // temp fix: use USDC adddress
    weth: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", // temp fix: use USDC adddress
    milestones: "",
    bridgeReceiver: "",
    bridgeSender: "",
    directPayAxelar: "",
    batch: "",
    usdc: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
  },
};

export const contractMappingForChainId = (chainId: number) => {
  switch (chainId) {
    case 80001:
      return ContractAddressMapping.mumbai;
    case 44787:
      return ContractAddressMapping.alfajores;
    case 137:
      return ContractAddressMapping.polygon;
    default:
      return undefined;
  }
};
