export interface MilestonesData {
    moduleName: "milestones";
    type: "invoice" | "payment";
    worker: string;
    client: string;
    milestones: number[];
    ipfsHash?: string;
}
export interface MilestoneProps {
    currency: string;
    amount: number;
    module: MilestonesData;
}
export declare function writeMilestones({ module, amount, currency, }: MilestoneProps): Promise<void>;
