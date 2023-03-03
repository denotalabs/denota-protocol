export const DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";

export const DENOTA_SUPPORTED_CHAIN_IDS = [];

export function setProvider(provider: any) {}

interface ApproveTokenProps {
  token: string;
  approvalAmount: number;
}

export function approveToken({}: ApproveTokenProps) {}

interface DirectPayProps {
  recipient: string;
  token: string;
  amount: number;
  note?: string;
  file?: any; // TODO: use correct type
}

export function sendDirectPayment({
  recipient,
  token,
  amount,
  note,
  file,
}: DirectPayProps) {}

export function sendDirectPayInvoice({
  recipient,
  token,
  amount,
  note,
  file,
}: DirectPayProps) {}

interface FundDirectPayProps {
  cheqId: number;
}

export function fundDirectPayInvoice({}: FundDirectPayProps) {}

interface ReversiblePaymentProps {
  recipient: string;
  token: string;
  amount: number;
  note?: string;
  file?: any; // TODO: use correct type
  inspectionPeriod: number;
}

export function sendReversiblePayent({}: ReversiblePaymentProps) {}

export function sendReversibleInvoice({}: ReversiblePaymentProps) {}

interface ReversePaymentProps {
  cheqId: number;
}

export function reversePayment({}: ReversePaymentProps) {}

export function fetchNotas(query: string) {}
