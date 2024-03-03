import { Bytes, ethereum, log } from "@graphprotocol/graph-ts";

import {
  DirectSendData,
  SimpleCashData,
  ReversibleReleaseData,
  ReversibleByBeforeDateData,
  CashBeforeDateData,
  CashBeforeDateDripData
} from "../generated/schema";


function decodeDirectSendData(notaId: string, hookData: Bytes): void {
  let entity = new DirectSendData(notaId);
  entity.raw = hookData;
  entity.nota = notaId;
  const decoded = ethereum.decode('(string,string)', hookData);
  if (decoded) {
    const argTuple = decoded.toTuple();
    const externalURI = argTuple[0].toString();
    const imageURI = argTuple[1].toString();
    entity.externalURI = externalURI;
    entity.imageURI = imageURI;
  }
  entity.save();
}

function decodeSimpleCashData(notaId: string, hookData: Bytes): void {
  let entity = new SimpleCashData(notaId);
  const decoded = ethereum.decode('(string,string)', hookData);
  entity.raw = hookData;
  entity.nota = notaId;
  if (decoded) {
    const argTuple = decoded.toTuple();
    const externalURI = argTuple[0].toString();
    const imageURI = argTuple[1].toString();
    entity.externalURI = externalURI;
    entity.imageURI = imageURI;
  }
  entity.save();
}

function decodeReversibleReleaseData(notaId: string, hookData: Bytes): void {
  let entity = new ReversibleReleaseData(notaId);
  entity.raw = hookData;
  entity.nota = notaId;
  const decoded = ethereum.decode('(address,string,string)', hookData);
  if (decoded) {
    const argTuple = decoded.toTuple();
    const inspector = argTuple[0].toString();
    const externalURI = argTuple[1].toString();
    const imageURI = argTuple[2].toString();
    entity.externalURI = externalURI;
    entity.imageURI = imageURI;
    entity.inspector = inspector;
  }
  entity.save();
}

function decodeReversibleByBeforeDateData(notaId: string, hookData: Bytes): void {
  let entity = new ReversibleByBeforeDateData(notaId);
  entity.raw = hookData;
  entity.nota = notaId;
  const decoded = ethereum.decode('(address,uint256,string,string)', hookData);
  if (decoded) {
    const argTuple = decoded.toTuple();
    const inspector = argTuple[0].toString();
    const inspectionEnd = argTuple[1].toBigInt();
    const externalURI = argTuple[2].toString();
    const imageURI = argTuple[3].toString();
    entity.externalURI = externalURI;
    entity.imageURI = imageURI;
    entity.inspectionEnd = inspectionEnd;
    entity.inspector = inspector;
  }
  entity.save();
}

function decodeCashBeforeDateData(notaId: string, hookData: Bytes): void {
  let entity = new CashBeforeDateData(notaId);
  entity.raw = hookData;
  entity.nota = notaId;
  const decoded = ethereum.decode('(address,string,string)', hookData);
  if (decoded) {
    const argTuple = decoded.toTuple();
    const expirationDate = argTuple[0].toBigInt();
    const externalURI = argTuple[1].toString();
    const imageURI = argTuple[2].toString();
    entity.externalURI = externalURI;
    entity.imageURI = imageURI;
    entity.expirationDate = expirationDate;
  }
  entity.save();
}

function decodeCashBeforeDateDripData(notaId: string, hookData: Bytes): void {
  let entity = new CashBeforeDateDripData(notaId);
  entity.raw = hookData;
  entity.nota = notaId;
  const decoded = ethereum.decode('(uint256,uint256,uint256,string,string)', hookData);
  if (decoded) {
    const argTuple = decoded.toTuple();
    const dripAmount = argTuple[0].toBigInt();
    const dripPeriod = argTuple[1].toBigInt();
    const expirationDate = argTuple[2].toBigInt();
    const externalURI = argTuple[3].toString();
    const imageURI = argTuple[4].toString();
    entity.externalURI = externalURI;
    entity.imageURI = imageURI;
    entity.dripAmount = dripAmount;
    entity.dripPeriod = dripPeriod;
    entity.expirationDate = expirationDate;
  }
  entity.save();
}

export function handleHookData(notaId: string, hookAddress: string, hookData: Bytes): void {
  if (hookAddress == "0x00000003672153a114583fa78c3d313d4e3cae40".toLowerCase()
       || hookAddress == "0x000000002e777f8f03b71f1ea16f2bdb8208fcc8".toLowerCase()
       || hookAddress == "0x0000000081bcd0c1fb0bf3a5a559d0575f2d3662".toLowerCase()) {
    decodeDirectSendData(notaId, hookData);
  } else if (hookAddress == "0x000000000AE1D0831c0C7485eAcc847D2F57EBb9".toLowerCase()) {
    decodeSimpleCashData(notaId, hookData);
  } else if (hookAddress == "0x0000000078E1A913Ee98c64CEc34fe813872eF79".toLowerCase()) {
    decodeReversibleReleaseData(notaId, hookData);
  } else if (hookAddress == "0x00000000115e79ea19439db1095327acbd810bf7".toLowerCase()) {
    decodeReversibleByBeforeDateData(notaId, hookData);
  } else if (hookAddress == "0x00000000123157038206FeFeB809823016331fF2".toLowerCase()
             || hookAddress == "0x000000005891889951d265d6d7ad3444b68f8887".toLowerCase()) {
    decodeCashBeforeDateData(notaId, hookData);
  } else if (hookAddress == "0x00000000e8c13602e4d483a90af69e7582a43373".toLowerCase()) {
    decodeCashBeforeDateDripData(notaId, hookData);
  } else {
    log.warning("Unknown hook address: {}", [hookAddress]);
  }
}