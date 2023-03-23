export const ContractAddressMapping = {
  mumbai: {
    DataTypes: "0x4287f38FecFC24Bd80F643f682E727bD6407F484",
    Errors: "0x2418EF1Dab6A0Db2F05ea0A03221d19708388F26",
    Events: "0x0faCA1284C7D037120D5D7C66Cd655B777c8807D",
    registrar: "0x3D8B0f18a9456ecB5403ED2910773910BdA1ffD9",
    escrow: "0x5EeBfCDCb192B71Efc497D240bbD3994b21a5E4e",
    directPay: "0x54A011b3770752Bf24ca05B53fdc6A45d8d68307",
    milestones: "",
    dai: "0xc5B6c09dc6595Eb949739f7Cd6A8d542C2aabF4b",
    weth: "0xe37F99b03C7B4f4d71eE20e8eF3AC4E138D47F80",
  },
  alfajores: {
    DataTypes: "0xC6612B00C0f64b4866880fd863290337D66b0796",
    Errors: "0x6E3cFc8ded54fcBA3C59b1c749B77AD8bF9DC00f",
    Events: "0x2531A31a31C9f306F2aa3a7AF5F5b09E49Bd0A28",
    registrar: "0xCc7a0cE9E0411BF5083491Fe502261319a19201d",
    directPay: "0x1ddc87BdEEdb29ef6d1C6C7Fa7cEeA1a7F3c098b",
    milestones: "",
    dai: "0xe314158969CCa87E88350196308f96D879D18b83",
    weth: "0x722D4CED724b69A416AfA50860cEd7B71a1bf689",
    escrow: "0x3773f4ef0A9b0C5d49dfb2b3cA3C6FbE293a5926",
  },
};

export const contractMappingForChainId = (chainId: number) => {
  switch (chainId) {
    case 80001:
      return ContractAddressMapping.mumbai;
    case 44787:
      return ContractAddressMapping.alfajores;
    default:
      return undefined;
  }
};
