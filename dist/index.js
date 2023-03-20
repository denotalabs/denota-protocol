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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getNotasQueryURL = exports.sendBatchPaymentFromCSV = exports.sendBatchPayment = exports.reverse = exports.fund = exports.write = exports.approveToken = exports.setProvider = exports.DENOTA_SUPPORTED_CHAIN_IDS = exports.DENOTA_APIURL_REMOTE_MUMBAI = void 0;
var ethers_1 = require("ethers");
var TestERC20_json_1 = __importDefault(require("./abis/ERC20.sol/TestERC20.json"));
var chainInfo_1 = require("./chainInfo");
exports.DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";
var CheqRegistrar_json_1 = __importDefault(require("./abis/CheqRegistrar.sol/CheqRegistrar.json"));
exports.DENOTA_SUPPORTED_CHAIN_IDS = [80001];
var state = {
    blockchainState: {
        account: "",
        registrar: null,
        registrarAddress: "",
        signer: null,
        directPayAddress: "",
        chainId: 0,
        dai: null,
        weth: null,
    },
};
function setProvider(web3Connection) {
    return __awaiter(this, void 0, void 0, function () {
        var provider, signer, account, chainId, contractMapping, registrar, dai, weth;
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
                        dai = new ethers_1.ethers.Contract(contractMapping.dai, TestERC20_json_1.default.abi, signer);
                        weth = new ethers_1.ethers.Contract(contractMapping.weth, TestERC20_json_1.default.abi, signer);
                        state.blockchainState = {
                            signer: signer,
                            account: account,
                            registrarAddress: contractMapping.registrar,
                            registrar: registrar,
                            directPayAddress: contractMapping.directPay,
                            chainId: chainId,
                            dai: dai,
                            weth: weth,
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
            return state.blockchainState.dai;
        case "WETH":
            return state.blockchainState.weth;
    }
}
function tokenAddressForCurrency(currency) {
    var _a, _b;
    switch (currency) {
        case "DAI":
            return (_a = state.blockchainState.dai) === null || _a === void 0 ? void 0 : _a.address;
        case "WETH":
            return (_b = state.blockchainState.weth) === null || _b === void 0 ? void 0 : _b.address;
        case "NATIVE":
            return "0x0000000000000000000000000000000000000000";
    }
}
function approveToken(_a) {
    var currency = _a.currency, approvalAmount = _a.approvalAmount;
    return __awaiter(this, void 0, void 0, function () {
        var token, amountWei, tx;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    token = tokenForCurrency(currency);
                    amountWei = ethers_1.ethers.utils.parseEther(String(approvalAmount));
                    return [4 /*yield*/, (token === null || token === void 0 ? void 0 : token.functions.approve(state.blockchainState.registrar, amountWei))];
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
    var module = _a.module, amount = _a.amount, currency = _a.currency;
    return __awaiter(this, void 0, void 0, function () {
        var hash;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    if (!(module.moduleName == "Direct")) return [3 /*break*/, 2];
                    return [4 /*yield*/, writeDirectPay({ module: module, amount: amount, currency: currency })];
                case 1:
                    hash = _b.sent();
                    return [2 /*return*/, hash];
                case 2: return [2 /*return*/];
            }
        });
    });
}
exports.write = write;
function writeDirectPay(_a) {
    var _b, _c;
    var module = _a.module, amount = _a.amount, currency = _a.currency;
    return __awaiter(this, void 0, void 0, function () {
        var dueDate, imageHash, ipfsHash, utcOffset, dueTimestamp, d, today, receiver, owner, amountWei, payload, tokenAddress, msgValue, tx, receipt;
        return __generator(this, function (_d) {
            switch (_d.label) {
                case 0:
                    dueDate = module.dueDate, imageHash = module.imageHash, ipfsHash = module.ipfsHash;
                    utcOffset = new Date().getTimezoneOffset();
                    if (dueDate) {
                        dueTimestamp = Date.parse("".concat(dueDate, "T00:00:00Z")) / 1000 + utcOffset * 60;
                    }
                    else {
                        d = new Date();
                        today = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
                            .toISOString()
                            .slice(0, 10);
                        dueTimestamp = Date.parse("".concat(today, "T00:00:00Z")) / 1000 + utcOffset * 60;
                    }
                    owner = module.creditor;
                    if (module.type === "invoice") {
                        receiver = module.debitor;
                    }
                    else {
                        receiver = module.creditor;
                    }
                    amountWei = ethers_1.ethers.utils.parseEther(String(amount));
                    payload = ethers_1.ethers.utils.defaultAbiCoder.encode(["address", "uint256", "uint256", "address", "string", "string"], [
                        receiver,
                        amountWei,
                        dueTimestamp,
                        state.blockchainState.account,
                        imageHash !== null && imageHash !== void 0 ? imageHash : "",
                        ipfsHash !== null && ipfsHash !== void 0 ? ipfsHash : "",
                    ]);
                    tokenAddress = (_b = tokenAddressForCurrency(currency)) !== null && _b !== void 0 ? _b : "";
                    msgValue = tokenAddress === "0x0000000000000000000000000000000000000000" &&
                        module.type !== "invoice"
                        ? amountWei
                        : ethers_1.BigNumber.from(0);
                    return [4 /*yield*/, ((_c = state.blockchainState.registrar) === null || _c === void 0 ? void 0 : _c.write(tokenAddress, //currency
                        0, //escrowed
                        module.type === "invoice" ? 0 : amountWei, //instant
                        owner, state.blockchainState.directPayAddress, payload))];
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
function fund(_a) {
    var cheqId = _a.cheqId;
    return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_b) {
        return [2 /*return*/];
    }); });
}
exports.fund = fund;
function reverse(_a) {
    var cheqId = _a.cheqId;
    return __awaiter(this, void 0, void 0, function () { return __generator(this, function (_b) {
        return [2 /*return*/];
    }); });
}
exports.reverse = reverse;
function sendBatchPayment(_a) { }
exports.sendBatchPayment = sendBatchPayment;
function sendBatchPaymentFromCSV(csv) { }
exports.sendBatchPaymentFromCSV = sendBatchPaymentFromCSV;
function getNotasQueryURL() {
    switch (state.blockchainState.chainId) {
        case 80001:
            return "https://denota.klymr.me/graph/mumbai";
        case 44787:
            return "https://denota.klymr.me/graph/alfajores";
        default:
            return undefined;
    }
}
exports.getNotasQueryURL = getNotasQueryURL;
exports.default = { write: write };
