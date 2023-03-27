"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.fundDirectPay = exports.writeDirectPay = void 0;
var ethers_1 = require("ethers");
var __1 = require("..");
function writeDirectPay(_a) {
    var _b, _c;
    var module = _a.module, amount = _a.amount, currency = _a.currency;
    return __awaiter(this, void 0, void 0, function () {
        var dueDate, imageHash, ipfsHash, type, creditor, debitor, utcOffset, dueTimestamp, d, today, owner, receiver, amountWei, payload, tokenAddress, msgValue, tx, receipt;
        return __generator(this, function (_d) {
            switch (_d.label) {
                case 0:
                    dueDate = module.dueDate, imageHash = module.imageHash, ipfsHash = module.ipfsHash, type = module.type, creditor = module.creditor, debitor = module.debitor;
                    utcOffset = new Date().getTimezoneOffset();
                    if (dueDate) {
                        dueTimestamp = Date.parse(dueDate + "T00:00:00Z") / 1000 + utcOffset * 60;
                    }
                    else {
                        d = new Date();
                        today = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
                            .toISOString()
                            .slice(0, 10);
                        dueTimestamp = Date.parse(today + "T00:00:00Z") / 1000 + utcOffset * 60;
                    }
                    owner = creditor;
                    receiver = type === "invoice" ? debitor : creditor;
                    amountWei = ethers_1.ethers.utils.parseEther(String(amount));
                    payload = ethers_1.ethers.utils.defaultAbiCoder.encode(["address", "uint256", "uint256", "address", "string", "string"], [
                        receiver,
                        amountWei,
                        dueTimestamp,
                        __1.state.blockchainState.account,
                        imageHash !== null && imageHash !== void 0 ? imageHash : "",
                        ipfsHash !== null && ipfsHash !== void 0 ? ipfsHash : "",
                    ]);
                    tokenAddress = (_b = __1.tokenAddressForCurrency(currency)) !== null && _b !== void 0 ? _b : "";
                    msgValue = tokenAddress === "0x0000000000000000000000000000000000000000" &&
                        module.type === "payment"
                        ? amountWei
                        : ethers_1.BigNumber.from(0);
                    return [4 /*yield*/, ((_c = __1.state.blockchainState.registrar) === null || _c === void 0 ? void 0 : _c.write(tokenAddress, //currency
                        0, //escrowed
                        module.type === "invoice" ? 0 : amountWei, //instant
                        owner, __1.state.blockchainState.directPayAddress, payload, { value: msgValue }))];
                case 1:
                    tx = _d.sent();
                    return [4 /*yield*/, tx.wait()];
                case 2:
                    receipt = _d.sent();
                    return [2 /*return*/, receipt.transactionHash];
            }
        });
    });
}
exports.writeDirectPay = writeDirectPay;
function fundDirectPay(_a) {
    var _b;
    var cheqId = _a.cheqId, amount = _a.amount, tokenAddress = _a.tokenAddress;
    return __awaiter(this, void 0, void 0, function () {
        var payload, msgValue, tx, receipt;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0:
                    payload = ethers_1.ethers.utils.defaultAbiCoder.encode(["address"], [__1.state.blockchainState.account]);
                    msgValue = tokenAddress === "0x0000000000000000000000000000000000000000"
                        ? amount
                        : ethers_1.BigNumber.from(0);
                    return [4 /*yield*/, ((_b = __1.state.blockchainState.registrar) === null || _b === void 0 ? void 0 : _b.fund(cheqId, 0, // escrow
                        amount, // instant
                        payload, { value: msgValue }))];
                case 1:
                    tx = _c.sent();
                    return [4 /*yield*/, tx.wait()];
                case 2:
                    receipt = _c.sent();
                    return [2 /*return*/, receipt.transactionHash];
            }
        });
    });
}
exports.fundDirectPay = fundDirectPay;
