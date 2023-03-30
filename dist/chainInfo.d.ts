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
        milestones: string;
    };
    alfajores: {
        DataTypes: string;
        Errors: string;
        Events: string;
        registrar: string;
        directPay: string;
        escrow: string;
        dai: string;
        weth: string;
        milestones: string;
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
    milestones: string;
} | undefined;
