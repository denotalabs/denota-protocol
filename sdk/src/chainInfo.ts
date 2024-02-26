export const ContractAddressMapping = {
  polygon: {
    DataTypes: "",
    registrar: "0x000000003C9C54B98C17F5A8B05ADca5B3B041eD",
    directPay: "0x00000003672153a114583fa78c3d313d4e3cae40",
    simpleCash: "0x000000000AE1D0831c0C7485eAcc847D2F57EBb9",
    cashBeforeDate: "0x00000000123157038206FeFeB809823016331fF2",
    reversibleRelease: "0x0000000078E1A913Ee98c64CEc34fe813872eF79",
    reversibleByBeforeDate: "0x00000000115e79ea19439db1095327acbd810bf7",
    milestones: "",
    dai: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
    weth: "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",
    usdc: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
    usdce: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
    usdt: "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
    get: "0xdb725f82818De83e99F1dAc22A9b5B51d3d04DD4",
    bridgeReceiver: "",
    bridgeSender: "",
    directPayAxelar: "",
    batch: "",
  },
};

export const contractMappingForChainId = (chainId: number) => {
  switch (chainId) {
    case 137:
      return ContractAddressMapping.polygon;
    default:
      return undefined;
  }
};
