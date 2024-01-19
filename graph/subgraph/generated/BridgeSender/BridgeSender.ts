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

  get memoHash(): string {
    return this._event.parameters[0].value.toString();
  }

  get amount(): BigInt {
    return this._event.parameters[1].value.toBigInt();
  }

  get timestamp(): BigInt {
    return this._event.parameters[2].value.toBigInt();
  }

  get creditor(): Address {
    return this._event.parameters[3].value.toAddress();
  }

  get debtor(): Address {
    return this._event.parameters[4].value.toAddress();
  }

  get chainId(): BigInt {
    return this._event.parameters[5].value.toBigInt();
  }

  get destinationChain(): string {
    return this._event.parameters[6].value.toString();
  }
}

export class BridgeSender extends ethereum.SmartContract {
  static bind(address: Address): BridgeSender {
    return new BridgeSender("BridgeSender", address);
  }

  gasReceiver(): Address {
    let result = super.call("gasReceiver", "gasReceiver():(address)", []);

    return result[0].toAddress();
  }

  try_gasReceiver(): ethereum.CallResult<Address> {
    let result = super.tryCall("gasReceiver", "gasReceiver():(address)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
  }

  gateway(): Address {
    let result = super.call("gateway", "gateway():(address)", []);

    return result[0].toAddress();
  }

  try_gateway(): ethereum.CallResult<Address> {
    let result = super.tryCall("gateway", "gateway():(address)", []);
    if (result.reverted) {
      return new ethereum.CallResult();
    }
    let value = result.value;
    return ethereum.CallResult.fromValue(value[0].toAddress());
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

  get gateway_(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get gasReceiver_(): Address {
    return this._call.inputValues[1].value.toAddress();
  }
}

export class ConstructorCall__Outputs {
  _call: ConstructorCall;

  constructor(call: ConstructorCall) {
    this._call = call;
  }
}

export class CreateRemoteNotaCall extends ethereum.Call {
  get inputs(): CreateRemoteNotaCall__Inputs {
    return new CreateRemoteNotaCall__Inputs(this);
  }

  get outputs(): CreateRemoteNotaCall__Outputs {
    return new CreateRemoteNotaCall__Outputs(this);
  }
}

export class CreateRemoteNotaCall__Inputs {
  _call: CreateRemoteNotaCall;

  constructor(call: CreateRemoteNotaCall) {
    this._call = call;
  }

  get token(): Address {
    return this._call.inputValues[0].value.toAddress();
  }

  get amount(): BigInt {
    return this._call.inputValues[1].value.toBigInt();
  }

  get owner(): Address {
    return this._call.inputValues[2].value.toAddress();
  }

  get memoURI_(): string {
    return this._call.inputValues[3].value.toString();
  }

  get imageURI_(): string {
    return this._call.inputValues[4].value.toString();
  }

  get destinationChain(): string {
    return this._call.inputValues[5].value.toString();
  }

  get destinationAddress(): string {
    return this._call.inputValues[6].value.toString();
  }
}

export class CreateRemoteNotaCall__Outputs {
  _call: CreateRemoteNotaCall;

  constructor(call: CreateRemoteNotaCall) {
    this._call = call;
  }
}

export class ExecuteCall extends ethereum.Call {
  get inputs(): ExecuteCall__Inputs {
    return new ExecuteCall__Inputs(this);
  }

  get outputs(): ExecuteCall__Outputs {
    return new ExecuteCall__Outputs(this);
  }
}

export class ExecuteCall__Inputs {
  _call: ExecuteCall;

  constructor(call: ExecuteCall) {
    this._call = call;
  }

  get commandId(): Bytes {
    return this._call.inputValues[0].value.toBytes();
  }

  get sourceChain(): string {
    return this._call.inputValues[1].value.toString();
  }

  get sourceAddress(): string {
    return this._call.inputValues[2].value.toString();
  }

  get payload(): Bytes {
    return this._call.inputValues[3].value.toBytes();
  }
}

export class ExecuteCall__Outputs {
  _call: ExecuteCall;

  constructor(call: ExecuteCall) {
    this._call = call;
  }
}

export class ExecuteWithTokenCall extends ethereum.Call {
  get inputs(): ExecuteWithTokenCall__Inputs {
    return new ExecuteWithTokenCall__Inputs(this);
  }

  get outputs(): ExecuteWithTokenCall__Outputs {
    return new ExecuteWithTokenCall__Outputs(this);
  }
}

export class ExecuteWithTokenCall__Inputs {
  _call: ExecuteWithTokenCall;

  constructor(call: ExecuteWithTokenCall) {
    this._call = call;
  }

  get commandId(): Bytes {
    return this._call.inputValues[0].value.toBytes();
  }

  get sourceChain(): string {
    return this._call.inputValues[1].value.toString();
  }

  get sourceAddress(): string {
    return this._call.inputValues[2].value.toString();
  }

  get payload(): Bytes {
    return this._call.inputValues[3].value.toBytes();
  }

  get tokenSymbol(): string {
    return this._call.inputValues[4].value.toString();
  }

  get amount(): BigInt {
    return this._call.inputValues[5].value.toBigInt();
  }
}

export class ExecuteWithTokenCall__Outputs {
  _call: ExecuteWithTokenCall;

  constructor(call: ExecuteWithTokenCall) {
    this._call = call;
  }
}