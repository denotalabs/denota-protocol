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
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
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
exports.writeCrossChainNota = void 0;
var axelarjs_sdk_1 = require("@axelar-network/axelarjs-sdk");
var ethers_1 = require("ethers");
var __1 = require("..");
var chainInfo_1 = require("../chainInfo");
function writeCrossChainNota(_a) {
    var _b, _c;
    var module = _a.module, amount = _a.amount, currency = _a.currency, imageUrl = _a.imageUrl, ipfsHash = _a.ipfsHash;
    return __awaiter(this, void 0, void 0, function () {
        var creditor, amountWei, api, axelarFeeString, axelarFee, tokenAddress, msgValue, tx, receipt, txHash;
        return __generator(this, function (_d) {
            switch (_d.label) {
                case 0:
                    creditor = module.creditor;
                    amountWei = ethers_1.ethers.utils.parseEther(String(amount));
                    api = new axelarjs_sdk_1.AxelarQueryAPI({ environment: axelarjs_sdk_1.Environment.TESTNET });
                    return [4 /*yield*/, api.estimateGasFee(axelarjs_sdk_1.CHAINS.TESTNET["CELO"], axelarjs_sdk_1.CHAINS.TESTNET["POLYGON"], "CELO", 300000, // gas limit
                        1.2 // gas multiplier
                        )];
                case 1:
                    axelarFeeString = _d.sent();
                    axelarFee = ethers_1.BigNumber.from(axelarFeeString);
                    tokenAddress = (_b = (0, __1.tokenAddressForCurrency)(currency)) !== null && _b !== void 0 ? _b : "";
                    msgValue = tokenAddress === "0x0000000000000000000000000000000000000000"
                        ? amountWei.add(axelarFee)
                        : axelarFee;
                    return [4 /*yield*/, ((_c = __1.state.blockchainState.axelarBridgeSender) === null || _c === void 0 ? void 0 : _c.createRemoteNota(tokenAddress, //currency
                        amountWei, //amount
                        creditor, //owner
                        ipfsHash, imageUrl, "Polygon", //destinationChain
                        chainInfo_1.ContractAddressMapping.mumbai.bridgeReceiver, { value: msgValue }))];
                case 2:
                    tx = _d.sent();
                    return [4 /*yield*/, tx.wait()];
                case 3:
                    receipt = _d.sent();
                    txHash = receipt.transactionHash;
                    // Nota hasn't been minted yet so use tx hash as temp nota id
                    return [2 /*return*/, { txHash: txHash, notaId: txHash }];
            }
        });
    });
}
exports.writeCrossChainNota = writeCrossChainNota;
