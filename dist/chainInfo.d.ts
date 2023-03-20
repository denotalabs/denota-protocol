export declare const ContractAddressMapping: {
    mumbai: {
        DataTypes: string;
        Errors: string;
        Events: string;
        registrar: string;
        escrow: string;
        directPay: string;
        dai: string;
        weth: string;
    };
    alfajores: {
        DataTypes: string;
        Errors: string;
        Events: string;
        registrar: string;
        directPay: string;
        dai: string;
        weth: string;
        escrow: string;
    };
};
export declare const contractMappingForChainId: (chainId: number) => {
    DataTypes: string;
    Errors: string;
    Events: string;
    registrar: string;
    escrow: string;
    directPay: string;
    dai: string;
    weth: string;
} | undefined;
