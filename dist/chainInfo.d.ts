export declare const ContractAddressMapping: {
    mumbai: {
        CheqBase64Encoding: string;
        DataTypes: string;
        Errors: string;
        Events: string;
        registrar: string;
        directPay: string;
        dai: string;
        weth: string;
    };
    alfajores: {
        CheqBase64Encoding: string;
        DataTypes: string;
        Errors: string;
        Events: string;
        registrar: string;
        directPay: string;
        dai: string;
        weth: string;
    };
};
export declare const contractMappingForChainId: (chainId: number) => {
    CheqBase64Encoding: string;
    DataTypes: string;
    Errors: string;
    Events: string;
    registrar: string;
    directPay: string;
    dai: string;
    weth: string;
} | undefined;
