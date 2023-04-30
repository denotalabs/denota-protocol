export interface MilestonesData {
    moduleName: "milestones";
    type: "invoice" | "payment";
    worker: string;
    client: string;
    milestones: number[];
}
export interface MilestoneProps {
    currency: string;
    amount: number;
    ipfsHash?: string;
    module: MilestonesData;
}
export declare function writeMilestones({ module, amount, currency, ipfsHash, }: MilestoneProps): Promise<{
    txHash: string;
    notaId: string;
}>;
