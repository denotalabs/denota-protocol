export declare const ContractAddressMapping: {
    mumbai: {
        cheq: string;
        dai: string;
        weth: string;
        selfSignedBroker: string;
        directPayModule: string;
    };
    local: {
        cheq: string;
        dai: string;
        weth: string;
        selfSignedBroker: string;
        directPayModule: string;
    };
};
export declare const contractMappingForChainId: (chainId: number) => {
    cheq: string;
    dai: string;
    weth: string;
    selfSignedBroker: string;
    directPayModule: string;
} | undefined;
