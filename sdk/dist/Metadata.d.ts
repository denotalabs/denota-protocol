export declare function uploadMetadata(file?: File, note?: string, tags?: string): Promise<{
    ipfsHash: string;
    imageUrl: string;
} | {
    ipfsHash: undefined;
    imageUrl: undefined;
}>;
