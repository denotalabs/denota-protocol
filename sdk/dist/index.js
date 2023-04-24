"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
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
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.contractMappingForChainId = exports.getNotasQueryURL = exports.sendBatchPaymentFromCSV = exports.sendBatchPayment = exports.cash = exports.fund = exports.write = exports.approveToken = exports.notaIdFromLog = exports.tokenAddressForCurrency = exports.setProvider = exports.state = exports.DENOTA_SUPPORTED_CHAIN_IDS = void 0;
var ethers_1 = require("ethers");
var TestERC20_json_1 = __importDefault(require("./abis/ERC20.sol/TestERC20.json"));
var chainInfo_1 = require("./chainInfo");
var client_1 = require("@apollo/client");
var BridgeSender_json_1 = __importDefault(require("./abis/BridgeSender.sol/BridgeSender.json"));
var CheqRegistrar_json_1 = __importDefault(require("./abis/CheqRegistrar.sol/CheqRegistrar.json"));
var Events_json_1 = __importDefault(require("./abis/Events.sol/Events.json"));
var AxelarBridge_1 = require("./modules/AxelarBridge");
var DirectPay_1 = require("./modules/DirectPay");
var Milestones_1 = require("./modules/Milestones");
var ReversibleRelease_1 = require("./modules/ReversibleRelease");
exports.DENOTA_SUPPORTED_CHAIN_IDS = [80001, 44787];
exports.state = {
    blockchainState: {
        account: "",
        registrar: null,
        registrarAddress: "",
        signer: null,
        directPayAddress: "",
        chainId: 0,
        dai: null,
        weth: null,
        reversibleReleaseAddress: "",
        milestonesAddress: "",
        axelarBridgeSender: null,
    },
};
function setProvider(web3Connection) {
    return __awaiter(this, void 0, void 0, function () {
        var provider, signer, account, chainId, contractMapping, registrar, axelarBridgeSender, dai, weth;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    provider = new ethers_1.ethers.providers.Web3Provider(web3Connection);
                    signer = provider.getSigner();
                    return [4 /*yield*/, signer.getAddress()];
                case 1:
                    account = _a.sent();
                    return [4 /*yield*/, provider.getNetwork()];
                case 2:
                    chainId = (_a.sent()).chainId;
                    contractMapping = (0, chainInfo_1.contractMappingForChainId)(chainId);
                    if (contractMapping) {
                        registrar = new ethers_1.ethers.Contract(contractMapping.registrar, CheqRegistrar_json_1.default.abi, signer);
                        axelarBridgeSender = new ethers_1.ethers.Contract(contractMapping.bridgeSender, BridgeSender_json_1.default.abi, signer);
                        dai = new ethers_1.ethers.Contract(contractMapping.dai, TestERC20_json_1.default.abi, signer);
                        weth = new ethers_1.ethers.Contract(contractMapping.weth, TestERC20_json_1.default.abi, signer);
                        exports.state.blockchainState = {
                            signer: signer,
                            account: account,
                            registrarAddress: contractMapping.registrar,
                            registrar: registrar,
                            directPayAddress: contractMapping.directPay,
                            chainId: chainId,
                            dai: dai,
                            weth: weth,
                            reversibleReleaseAddress: contractMapping.escrow,
                            milestonesAddress: contractMapping.milestones,
                            axelarBridgeSender: axelarBridgeSender,
                        };
                    }
                    return [2 /*return*/];
            }
        });
    });
}
exports.setProvider = setProvider;
function tokenForCurrency(currency) {
    switch (currency) {
        case "DAI":
            return exports.state.blockchainState.dai;
        case "WETH":
            return exports.state.blockchainState.weth;
    }
}
function tokenAddressForCurrency(currency) {
    var _a, _b;
    switch (currency) {
        case "DAI":
            return (_a = exports.state.blockchainState.dai) === null || _a === void 0 ? void 0 : _a.address;
        case "WETH":
            return (_b = exports.state.blockchainState.weth) === null || _b === void 0 ? void 0 : _b.address;
        case "NATIVE":
            return "0x0000000000000000000000000000000000000000";
    }
}
exports.tokenAddressForCurrency = tokenAddressForCurrency;
function notaIdFromLog(receipt) {
    var iface = new ethers_1.ethers.utils.Interface(Events_json_1.default.abi);
    var writtenLog = receipt.logs
        .map(function (log) {
        try {
            return iface.parseLog(log);
        }
        catch (_a) {
            return {};
        }
    })
        .filter(function (log) {
        return log.name === "Written";
    });
    var id = writtenLog[0].args[1];
    return id.toString();
}
exports.notaIdFromLog = notaIdFromLog;
function approveToken(_a) {
    var currency = _a.currency, approvalAmount = _a.approvalAmount;
    return __awaiter(this, void 0, void 0, function () {
        var token, amountWei, tx;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    token = tokenForCurrency(currency);
                    amountWei = ethers_1.ethers.utils.parseEther(String(approvalAmount));
                    return [4 /*yield*/, (token === null || token === void 0 ? void 0 : token.functions.approve(exports.state.blockchainState.registrar, amountWei))];
                case 1:
                    tx = _b.sent();
                    return [4 /*yield*/, tx.wait()];
                case 2:
                    _b.sent();
                    return [2 /*return*/];
            }
        });
    });
}
exports.approveToken = approveToken;
function write(_a) {
    var module = _a.module, props = __rest(_a, ["module"]);
    return __awaiter(this, void 0, void 0, function () {
        var _b;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0:
                    _b = module.moduleName;
                    switch (_b) {
                        case "direct": return [3 /*break*/, 1];
                        case "reversibleRelease": return [3 /*break*/, 3];
                        case "milestones": return [3 /*break*/, 5];
                        case "crosschain": return [3 /*break*/, 6];
                    }
                    return [3 /*break*/, 7];
                case 1: return [4 /*yield*/, (0, DirectPay_1.writeDirectPay)(__assign({ module: module }, props))];
                case 2: return [2 /*return*/, _c.sent()];
                case 3: return [4 /*yield*/, (0, ReversibleRelease_1.writeReversibleRelease)(__assign({ module: module }, props))];
                case 4: return [2 /*return*/, _c.sent()];
                case 5: return [2 /*return*/, (0, Milestones_1.writeMilestones)(__assign({ module: module }, props))];
                case 6: return [2 /*return*/, (0, AxelarBridge_1.writeCrossChainNota)(__assign({ module: module }, props))];
                case 7: return [2 /*return*/];
            }
        });
    });
}
exports.write = write;
function fund(_a) {
    var notaId = _a.notaId;
    return __awaiter(this, void 0, void 0, function () {
        var notaQuery, client, data, nota, amount, _b;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0:
                    notaQuery = "\n  query cheqs($cheq: String ){\n    cheqs(where: { id: $cheq }, first: 1)  {\n      erc20 {\n        id\n      }\n      moduleData {\n        ... on DirectPayData {\n          __typename\n          amount\n        }\n        ... on ReversiblePaymentData {\n          __typename\n          amount\n        }\n      }\n    }\n  }\n";
                    client = new client_1.ApolloClient({
                        uri: getNotasQueryURL(),
                        cache: new client_1.InMemoryCache(),
                    });
                    return [4 /*yield*/, client.query({
                            query: (0, client_1.gql)(notaQuery),
                            variables: {
                                cheq: notaId,
                            },
                        })];
                case 1:
                    data = _c.sent();
                    nota = data["data"]["cheqs"][0];
                    amount = ethers_1.BigNumber.from(nota.moduleData.amount);
                    _b = nota.moduleData.__typename;
                    switch (_b) {
                        case "DirectPayData": return [3 /*break*/, 2];
                        case "ReversiblePaymentData": return [3 /*break*/, 4];
                    }
                    return [3 /*break*/, 6];
                case 2: return [4 /*yield*/, (0, DirectPay_1.fundDirectPay)({
                        notaId: notaId,
                        amount: amount,
                        tokenAddress: nota.erc20.id,
                    })];
                case 3: return [2 /*return*/, _c.sent()];
                case 4: return [4 /*yield*/, (0, ReversibleRelease_1.fundReversibleRelease)({
                        notaId: notaId,
                        amount: amount,
                        tokenAddress: nota.erc20.id,
                    })];
                case 5: return [2 /*return*/, _c.sent()];
                case 6: return [2 /*return*/];
            }
        });
    });
}
exports.fund = fund;
function cash(_a) {
    var notaId = _a.notaId, type = _a.type;
    return __awaiter(this, void 0, void 0, function () {
        var notaQuery, client, data, nota, amount, _b;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0:
                    notaQuery = "\n    query cheqs($cheq: String ){\n      cheqs(where: { id: $cheq }, first: 1)  {\n        moduleData {\n          ... on DirectPayData {\n            __typename\n            amount\n            creditor {\n              id\n            }\n            debtor {\n              id\n            }\n            dueDate\n          }\n          ... on ReversiblePaymentData {\n            __typename\n            amount\n            creditor {\n              id\n            }\n            debtor {\n              id\n            }\n          }\n        }\n    }\n    }\n  ";
                    client = new client_1.ApolloClient({
                        uri: getNotasQueryURL(),
                        cache: new client_1.InMemoryCache(),
                    });
                    return [4 /*yield*/, client.query({
                            query: (0, client_1.gql)(notaQuery),
                            variables: {
                                cheq: notaId,
                            },
                        })];
                case 1:
                    data = _c.sent();
                    nota = data["data"]["cheqs"][0];
                    amount = ethers_1.BigNumber.from(nota.moduleData.amount);
                    _b = nota.moduleData.__typename;
                    switch (_b) {
                        case "ReversiblePaymentData": return [3 /*break*/, 2];
                    }
                    return [3 /*break*/, 4];
                case 2: return [4 /*yield*/, (0, ReversibleRelease_1.cashReversibleRelease)({
                        notaId: notaId,
                        creditor: nota.moduleData.creditor.id,
                        debtor: nota.moduleData.debtor.id,
                        amount: amount,
                        type: type,
                    })];
                case 3: return [2 /*return*/, _c.sent()];
                case 4: return [2 /*return*/];
            }
        });
    });
}
exports.cash = cash;
function sendBatchPayment(_a) { }
exports.sendBatchPayment = sendBatchPayment;
function sendBatchPaymentFromCSV(csv) { }
exports.sendBatchPaymentFromCSV = sendBatchPaymentFromCSV;
function getNotasQueryURL() {
    switch (exports.state.blockchainState.chainId) {
        case 80001:
            return "https://denota.klymr.me/graph/mumbai";
        case 44787:
            return "https://denota.klymr.me/graph/alfajores";
        default:
            return undefined;
    }
}
exports.getNotasQueryURL = getNotasQueryURL;
exports.contractMappingForChainId = chainInfo_1.contractMappingForChainId;
exports.default = {
    approveToken: approveToken,
    write: write,
    fund: fund,
    cash: cash,
    sendBatchPayment: sendBatchPayment,
    sendBatchPaymentFromCSV: sendBatchPaymentFromCSV,
    getNotasQueryURL: getNotasQueryURL,
    contractMappingForChainId: exports.contractMappingForChainId,
};
