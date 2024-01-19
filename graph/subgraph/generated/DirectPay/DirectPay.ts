// THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY.

import {
  ethereum,
  JSONValue,
  TypedMap,
  Entity,
  Bytes,
  Address,
  BigInt
} from "@graphprotocol/graph-ts";

export class PaymentCreated extends ethereum.Event {
  get params(): PaymentCreated__Params {
    return new PaymentCreated__Params(this);
  }
}

export class PaymentCreated__Params {
  _event: PaymentCreated;

  constructor(event: PaymentCreated) {
    this._event = event;
  }

  get cheqId(): BigInt {
    return this._event.parameters[0].value.toBigInt();
  }

  get memoHash(): string {
    return this._event.parameters[1].value.toString();
  }

  get amount(): BigInt {
    return this._event.parameters[2].value.toBigInt();
  }

  get timestamp(): BigInt {
    return this._event.parameters[3].value.toBigInt();
  }

  get referer(): Address {
    return this._event.parameters[4].value.toAddress();
  }

  get creditor(): Address {
    return this._event.parameters[5].value.toAddress();
  }

  get debtor(): Address {
    return this._event.parameters[6].value.toAddress();
  }

  get dueDate(): BigInt {
    return this._event.parameters[7].value.toBigInt();
  }
}

export class DirectPay__dappOperatorFeesResult {
  value0: BigInt;
  value1: BigInt;
  value2: BigInt;
  value3: BigInt;

  constructor(value0: BigInt, value1: BigInt, value2: BigInt, value3: BigInt) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value2;
    this.value3 = value3;
  }

  toMap(): TypedMap<string, ethereum.Value> {
    let map = new TypedMap<string, ethereum.Value>();
    map.set("value0", ethereum.Value.fromUnsignedBigInt(this.value0));
    map.set("value1", ethereum.Value.fromUnsignedBigInt(this.value1));
    map.set("value2", ethereum.Value.fromUnsignedBigInt(this.value2));
    map.set("value3", ethereum.Value.fromUnsignedBigInt(this.value3));
    return map;
  }
}

export class DirectPay__getFeesResultValue0Struct extends ethereum.Tuple {
  get writeBPS(): BigInt {
    return this[0].toBigInt();
  }

  get transferBPS(): BigInt {
    return this[1].toBigInt();
  }

  get fundBPS(): BigInt {
    return this[2].toBigInt();
  }

  get cashBPS(): BigInt {
    return this[3].toBigInt();
  }
}

export class DirectPay__payInfoResult {
  value0: Address;
  value1: Address;
  value2: BigInt;
  value3: boolean;
  value4: string;
  value5: string;

  constructor(
    value0: Address,
    value1: Address,
    value2: BigInt,
    value3: boolean,
    value4: string,
    value5: string
  ) {
    this.value0 = value0;
    this.value1 = value1;
    this.value2 = value2;
    this.value3 = value3;
    this.value4 = value4;
    this.value5 = value5;
  }

  toMap(): TypedMap<string, ethereum.Value> {
    let map = new TypedMap<string, ethereum.Value>();
    map.set("value0", ethereum.Value.fromAddress(this.value0));
    map.set("value1", ethereum.Value.fromAddress(this.value1));
    map.set("value2", ethereum.Value.fromUnsignedBigInt(this.value2));
    map.set("value3", ethereum.Value.fromBoolean(this.value3));
    map.set("value4", ethereum.Value.fromString(this.value4));
    map.set("value5", ethereum.Value.fromString(this.value5));
    return map;
  }
}

export class DirectPay__processCashInputParam5Struct extends ethereum.Tuple {
  get currency(): Address {
    return this[0].toAddress();
  }

  get escrowed(): BigInt {
    return this[1].toBigInt();
  }

  get createdAt(): BigInt {
    return this[2].toBigInt();
  }

  get module(): Address {
    return this[3].toAddress();
  }
}

export class DirectPay__processFundInputCheqStruct extends ethereum.Tuple {
  get currency(): Address {
    return this[0].toAddress();
  }

  get escrowed(): BigInt {
    return this[1].toBigInt();
  }

  get createdAt(): BigInt {
    return this[2].toBigInt();
  }

  get module(): Address {
    return this[3].toAddress();
  }
}

export class DirectPay extends ethereum.SmartContract {
  static bind(address: Address): DirectPay {
    return new DirectPay("DirectPay", address);
  }

  REGISTRAR(): Address {
    let result = super.call("REGISTRAR", "REGISTRAR():(address)", []);

    return result[0].toAddress();
  }

  try_REGISTRAR(): ethereum.CallResult<Address> {
    let result = super.tryCall("REGISTRAR", "REGISTRAR():(address)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  _URI(): string {
    let result = super.call("_URI", "_URI():(string)", []);

    return result[0].toString();
  }

  try__URI(): ethereum.CallResult<string> {
    let result = super.tryCall("_URI", "_URI():(string)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toString());
  }

  dappOperatorFees(param0: Address): DirectPay__dappOperatorFeesResult {
    let result = super.call(
      "dappOperatorFees",
      "dappOperatorFees(address):(uint256,uint256,uint256,uint256)",
      [ethereum.Value.fromAddress(param0)]
    );

    return new DirectPay__dappOperatorFeesResult(
      result[0].toBigInt(),
      result[1].toBigInt(),
      result[2].toBigInt(),
      result[3].toBigInt()
    );
  }

  try_dappOperatorFees(
    param0: Address
  ): ethereum.CallResult<DirectPay__dappOperatorFeesResult> {
    let result = super.tryCall(
      "dappOperatorFees",
      "dappOperatorFees(address):(uint256,uint256,uint256,uint256)",
      [ethereum.Value.fromAddress(param0)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      new DirectPay__dappOperatorFeesResult(
        value[0].toBigInt(),
        value[1].toBigInt(),
        value[2].toBigInt(),
        value[3].toBigInt()
      )
    );
  }

  getFees(dappOperator: Address): DirectPay__getFeesResultValue0Struct {
    let result = super.call(
      "getFees",
      "getFees(address):((uint256,uint256,uint256,uint256))",
      [ethereum.Value.fromAddress(dappOperator)]
    );

    return changetype<DirectPay__getFeesResultValue0Struct>(
      result[0].toTuple()
    );
  }

  try_getFees(
    dappOperator: Address
  ): ethereum.CallResult<DirectPay__getFeesResultValue0Struct> {
    let result = super.tryCall(
      "getFees",
      "getFees(address):((uint256,uint256,uint256,uint256))",
      [ethereum.Value.fromAddress(dappOperator)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      changetype<DirectPay__getFeesResultValue0Struct>(value[0].toTuple())
    );
  }

  payInfo(param0: BigInt): DirectPay__payInfoResult {
    let result = super.call(
      "payInfo",
      "payInfo(uint256):(address,address,uint256,bool,string,string)",
      [ethereum.Value.fromUnsignedBigInt(param0)]
    );

    return new DirectPay__payInfoResult(
      result[0].toAddress(),
      result[1].toAddress(),
      result[2].toBigInt(),
      result[3].toBoolean(),
      result[4].toString(),
      result[5].toString()
    );
  }

  try_payInfo(param0: BigInt): ethereum.CallResult<DirectPay__payInfoResult> {
    let result = super.tryCall(
      "payInfo",
      "payInfo(uint256):(address,address,uint256,bool,string,string)",
      [ethereum.Value.fromUnsignedBigInt(param0)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(
      new DirectPay__payInfoResult(
        value[0].toAddress(),
        value[1].toAddress(),
        value[2].toBigInt(),
        value[3].toBoolean(),
        value[4].toString(),
        value[5].toString()
      )
    );
  }

  processCash(
    param0: Address,
    param1: Address,
    param2: Address,
    param3: BigInt,
    param4: BigInt,
    param5: DirectPay__processCashInputParam5Struct,
    param6: Bytes
  ): BigInt {
    let result = super.call(
      "processCash",
      "processCash(address,address,address,uint256,uint256,(address,uint256,uint256,address),bytes):(uint256)",
      [
        ethereum.Value.fromAddress(param0),
        ethereum.Value.fromAddress(param1),
        ethereum.Value.fromAddress(param2),
        ethereum.Value.fromUnsignedBigInt(param3),
        ethereum.Value.fromUnsignedBigInt(param4),
        ethereum.Value.fromTuple(param5),
        ethereum.Value.fromBytes(param6)
      ]
    );

    return result[0].toBigInt();
  }

  try_processCash(
    param0: Address,
    param1: Address,
    param2: Address,
    param3: BigInt,
    param4: BigInt,
    param5: DirectPay__processCashInputParam5Struct,
    param6: Bytes
  ): ethereum.CallResult<BigInt> {
    let result = super.tryCall(
      "processCash",
      "processCash(address,address,address,uint256,uint256,(address,uint256,uint256,address),bytes):(uint256)",
      [
        ethereum.Value.fromAddress(param0),
        ethereum.Value.fromAddress(param1),
        ethereum.Value.fromAddress(param2),
        ethereum.Value.fromUnsignedBigInt(param3),
        ethereum.Value.fromUnsignedBigInt(param4),
        ethereum.Value.fromTuple(param5),
        ethereum.Value.fromBytes(param6)
      ]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBigInt());
  }

  processFund(
    param0: Address,
    owner: Address,
    amount: BigInt,
    instant: BigInt,
    cheqId: BigInt,
    cheq: DirectPay__processFundInputCheqStruct,
    initData: Bytes
  ): BigInt {
    let result = super.call(
      "processFund",
      "processFund(address,address,uint256,uint256,uint256,(address,uint256,uint256,address),bytes):(uint256)",
      [
        ethereum.Value.fromAddress(param0),
        ethereum.Value.fromAddress(owner),
        ethereum.Value.fromUnsignedBigInt(amount),
        ethereum.Value.fromUnsignedBigInt(instant),
        ethereum.Value.fromUnsignedBigInt(cheqId),
        ethereum.Value.fromTuple(cheq),
        ethereum.Value.fromBytes(initData)
      ]
    );

    return result[0].toBigInt();
  }

  try_processFund(
    param0: Address,
    owner: Address,
    amount: BigInt,
    instant: BigInt,
    cheqId: BigInt,
    cheq: DirectPay__processFundInputCheqStruct,
    initData: Bytes
  ): ethereum.CallResult<BigInt> {
    let result = super.tryCall(
      "processFund",
      "processFund(address,address,uint256,uint256,uint256,(address,uint256,uint256,address),bytes):(uint256)",
      [
        ethereum.Value.fromAddress(param0),
        ethereum.Value.fromAddress(owner),
        ethereum.Value.fromUnsignedBigInt(amount),
        ethereum.Value.fromUnsignedBigInt(instant),
        ethereum.Value.fromUnsignedBigInt(cheqId),
        ethereum.Value.fromTuple(cheq),
        ethereum.Value.fromBytes(initData)
      ]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBigInt());
  }

  processTokenURI(tokenId: BigInt): string {
    let result = super.call(
      "processTokenURI",
      "processTokenURI(uint256):(string)",
      [ethereum.Value.fromUnsignedBigInt(tokenId)]
    );

    return result[0].toString();
  }

  try_processTokenURI(tokenId: BigInt): ethereum.CallResult<string> {
    let result = super.tryCall(
      "processTokenURI",
      "processTokenURI(uint256):(string)",
      [ethereum.Value.fromUnsignedBigInt(tokenId)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toString());
  }

  processTransfer(
    caller: Address,
    approved: Address,
    owner: Address,
    param3: Address,
    param4: Address,
    param5: BigInt,
    currency: Address,
    escrowed: BigInt,
    param8: BigInt,
    data: Bytes
  ): BigInt {
    let result = super.call(
      "processTransfer",
      "processTransfer(address,address,address,address,address,uint256,address,uint256,uint256,bytes):(uint256)",
      [
        ethereum.Value.fromAddress(caller),
        ethereum.Value.fromAddress(approved),
        ethereum.Value.fromAddress(owner),
        ethereum.Value.fromAddress(param3),
        ethereum.Value.fromAddress(param4),
        ethereum.Value.fromUnsignedBigInt(param5),
        ethereum.Value.fromAddress(currency),
        ethereum.Value.fromUnsignedBigInt(escrowed),
        ethereum.Value.fromUnsignedBigInt(param8),
        ethereum.Value.fromBytes(data)
      ]
    );

    return result[0].toBigInt();
  }

  try_processTransfer(
    caller: Address,
    approved: Address,
    owner: Address,
    param3: Address,
    param4: Address,
    param5: BigInt,
    currency: Address,
    escrowed: BigInt,
    param8: BigInt,
    data: Bytes
  ): ethereum.CallResult<BigInt> {
    let result = super.tryCall(
      "processTransfer",
      "processTransfer(address,address,address,address,address,uint256,address,uint256,uint256,bytes):(uint256)",
      [
        ethereum.Value.fromAddress(caller),
        ethereum.Value.fromAddress(approved),
        ethereum.Value.fromAddress(owner),
        ethereum.Value.fromAddress(param3),
        ethereum.Value.fromAddress(param4),
        ethereum.Value.fromUnsignedBigInt(param5),
        ethereum.Value.fromAddress(currency),
        ethereum.Value.fromUnsignedBigInt(escrowed),
        ethereum.Value.fromUnsignedBigInt(param8),
        ethereum.Value.fromBytes(data)
      ]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBigInt());
  }

  processWrite(
    caller: Address,
    owner: Address,
    cheqId: BigInt,
    currency: Address,
    escrowed: BigInt,
    instant: BigInt,
    initData: Bytes
  ): BigInt {
    let result = super.call(
      "processWrite",
      "processWrite(address,address,uint256,address,uint256,uint256,bytes):(uint256)",
      [
        ethereum.Value.fromAddress(caller),
        ethereum.Value.fromAddress(owner),
        ethereum.Value.fromUnsignedBigInt(cheqId),
        ethereum.Value.fromAddress(currency),
        ethereum.Value.fromUnsignedBigInt(escrowed),
        ethereum.Value.fromUnsignedBigInt(instant),
        ethereum.Value.fromBytes(initData)
      ]
    );

    return result[0].toBigInt();
  }

  try_processWrite(
    caller: Address,
    owner: Address,
    cheqId: BigInt,
    currency: Address,
    escrowed: BigInt,
    instant: BigInt,
    initData: Bytes
  ): ethereum.CallResult<BigInt> {
    let result = super.tryCall(
      "processWrite",
      "processWrite(address,address,uint256,address,uint256,uint256,bytes):(uint256)",
      [
        ethereum.Value.fromAddress(caller),
        ethereum.Value.fromAddress(owner),
        ethereum.Value.fromUnsignedBigInt(cheqId),
        ethereum.Value.fromAddress(currency),
        ethereum.Value.fromUnsignedBigInt(escrowed),
        ethereum.Value.fromUnsignedBigInt(instant),
        ethereum.Value.fromBytes(initData)
      ]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBigInt());
  }

  revenue(param0: Address, param1: Address): BigInt {
    let result = super.call("revenue", "revenue(address,address):(uint256)", [
      ethereum.Value.fromAddress(param0),
      ethereum.Value.fromAddress(param1)
    ]);

    return result[0].toBigInt();
  }

  try_revenue(param0: Address, param1: Address): ethereum.CallResult<BigInt> {
    let result = super.tryCall(
      "revenue",
      "revenue(address,address):(uint256)",
      [ethereum.Value.fromAddress(param0), ethereum.Value.fromAddress(param1)]
    );
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toBigInt());
  }
}

export class ConstructorCall extends ethereum.Call {
  get inputs(): ConstructorCall__Inputs {
    return new ConstructorCall__Inputs(this);
  }

  get outputs(): ConstructorCall__Outputs {
    return new ConstructorCall__Outputs(this);
  }
}

export class ConstructorCall__Inputs {
  _call: ConstructorCall;

  constructor(call: ConstructorCall) {
    this._call = call;
  }

  get registrar(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get _fees(): ConstructorCall_feesStruct {
    return changetype<ConstructorCall_feesStruct>(
      this._call.inputValues[1].value.toTuple()
    );
  }

  get __baseURI(): string {
    return this._call.inputValues[2].value.toString();
  }
}

export class ConstructorCall__Outputs {
  _call: ConstructorCall;

  constructor(call: ConstructorCall) {
    this._call = call;
  }
}

export class ConstructorCall_feesStruct extends ethereum.Tuple {
  get writeBPS(): BigInt {
    return this[0].toBigInt();
  }

  get transferBPS(): BigInt {
    return this[1].toBigInt();
  }

  get fundBPS(): BigInt {
    return this[2].toBigInt();
  }

  get cashBPS(): BigInt {
    return this[3].toBigInt();
  }
}

export class ProcessFundCall extends ethereum.Call {
  get inputs(): ProcessFundCall__Inputs {
    return new ProcessFundCall__Inputs(this);
  }

  get outputs(): ProcessFundCall__Outputs {
    return new ProcessFundCall__Outputs(this);
  }
}

export class ProcessFundCall__Inputs {
  _call: ProcessFundCall;

  constructor(call: ProcessFundCall) {
    this._call = call;
  }

  get value0(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get owner(): Address {
    return this._call.inputValues[1].value.toAddress();
  }

  get amount(): BigInt {
    return this._call.inputValues[2].value.toBigInt();
  }

  get instant(): BigInt {
    return this._call.inputValues[3].value.toBigInt();
  }

  get cheqId(): BigInt {
    return this._call.inputValues[4].value.toBigInt();
  }

  get cheq(): ProcessFundCallCheqStruct {
    return changetype<ProcessFundCallCheqStruct>(
      this._call.inputValues[5].value.toTuple()
    );
  }

  get initData(): Bytes {
    return this._call.inputValues[6].value.toBytes();
  }
}

export class ProcessFundCall__Outputs {
  _call: ProcessFundCall;

  constructor(call: ProcessFundCall) {
    this._call = call;
  }

  get value0(): BigInt {
    return this._call.outputValues[0].value.toBigInt();
  }
}

export class ProcessFundCallCheqStruct extends ethereum.Tuple {
  get currency(): Address {
    return this[0].toAddress();
  }

  get escrowed(): BigInt {
    return this[1].toBigInt();
  }

  get createdAt(): BigInt {
    return this[2].toBigInt();
  }

  get module(): Address {
    return this[3].toAddress();
  }
}

export class ProcessTransferCall extends ethereum.Call {
  get inputs(): ProcessTransferCall__Inputs {
    return new ProcessTransferCall__Inputs(this);
  }

  get outputs(): ProcessTransferCall__Outputs {
    return new ProcessTransferCall__Outputs(this);
  }
}

export class ProcessTransferCall__Inputs {
  _call: ProcessTransferCall;

  constructor(call: ProcessTransferCall) {
    this._call = call;
  }

  get caller(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get approved(): Address {
    return this._call.inputValues[1].value.toAddress();
  }

  get owner(): Address {
    return this._call.inputValues[2].value.toAddress();
  }

  get value3(): Address {
    return this._call.inputValues[3].value.toAddress();
  }

  get value4(): Address {
    return this._call.inputValues[4].value.toAddress();
  }

  get value5(): BigInt {
    return this._call.inputValues[5].value.toBigInt();
  }

  get currency(): Address {
    return this._call.inputValues[6].value.toAddress();
  }

  get escrowed(): BigInt {
    return this._call.inputValues[7].value.toBigInt();
  }

  get value8(): BigInt {
    return this._call.inputValues[8].value.toBigInt();
  }

  get data(): Bytes {
    return this._call.inputValues[9].value.toBytes();
  }
}

export class ProcessTransferCall__Outputs {
  _call: ProcessTransferCall;

  constructor(call: ProcessTransferCall) {
    this._call = call;
  }

  get value0(): BigInt {
    return this._call.outputValues[0].value.toBigInt();
  }
}

export class ProcessWriteCall extends ethereum.Call {
  get inputs(): ProcessWriteCall__Inputs {
    return new ProcessWriteCall__Inputs(this);
  }

  get outputs(): ProcessWriteCall__Outputs {
    return new ProcessWriteCall__Outputs(this);
  }
}

export class ProcessWriteCall__Inputs {
  _call: ProcessWriteCall;

  constructor(call: ProcessWriteCall) {
    this._call = call;
  }

  get caller(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get owner(): Address {
    return this._call.inputValues[1].value.toAddress();
  }

  get cheqId(): BigInt {
    return this._call.inputValues[2].value.toBigInt();
  }

  get currency(): Address {
    return this._call.inputValues[3].value.toAddress();
  }

  get escrowed(): BigInt {
    return this._call.inputValues[4].value.toBigInt();
  }

  get instant(): BigInt {
    return this._call.inputValues[5].value.toBigInt();
  }

  get initData(): Bytes {
    return this._call.inputValues[6].value.toBytes();
  }
}

export class ProcessWriteCall__Outputs {
  _call: ProcessWriteCall;

  constructor(call: ProcessWriteCall) {
    this._call = call;
  }

  get value0(): BigInt {
    return this._call.outputValues[0].value.toBigInt();
  }
}

export class SetFeesCall extends ethereum.Call {
  get inputs(): SetFeesCall__Inputs {
    return new SetFeesCall__Inputs(this);
  }

  get outputs(): SetFeesCall__Outputs {
    return new SetFeesCall__Outputs(this);
  }
}

export class SetFeesCall__Inputs {
  _call: SetFeesCall;

  constructor(call: SetFeesCall) {
    this._call = call;
  }

  get _fees(): SetFeesCall_feesStruct {
    return changetype<SetFeesCall_feesStruct>(
      this._call.inputValues[0].value.toTuple()
    );
  }
}

export class SetFeesCall__Outputs {
  _call: SetFeesCall;

  constructor(call: SetFeesCall) {
    this._call = call;
  }
}

export class SetFeesCall_feesStruct extends ethereum.Tuple {
  get writeBPS(): BigInt {
    return this[0].toBigInt();
  }

  get transferBPS(): BigInt {
    return this[1].toBigInt();
  }

  get fundBPS(): BigInt {
    return this[2].toBigInt();
  }

  get cashBPS(): BigInt {
    return this[3].toBigInt();
  }
}

export class WithdrawFeesCall extends ethereum.Call {
  get inputs(): WithdrawFeesCall__Inputs {
    return new WithdrawFeesCall__Inputs(this);
  }

  get outputs(): WithdrawFeesCall__Outputs {
    return new WithdrawFeesCall__Outputs(this);
  }
}

export class WithdrawFeesCall__Inputs {
  _call: WithdrawFeesCall;

  constructor(call: WithdrawFeesCall) {
    this._call = call;
  }

  get token(): Address {
    return this._call.inputValues[0].value.toAddress();
  }
}

export class WithdrawFeesCall__Outputs {
  _call: WithdrawFeesCall;

  constructor(call: WithdrawFeesCall) {
    this._call = call;
  }
}