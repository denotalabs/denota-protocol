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
exports.fetchNotas = exports.sendBatchPaymentFromCSV = exports.sendBatchPayment = exports.sendMilestonePayment = exports.sendMilestoneInvoice = exports.reversePayment = exports.sendReversibleInvoice = exports.sendReversiblePayent = exports.fundDirectPayInvoice = exports.sendDirectPayInvoice = exports.sendDirectPayment = exports.approveToken = exports.write = exports.setProvider = exports.DENOTA_SUPPORTED_CHAIN_IDS = exports.DENOTA_APIURL_REMOTE_MUMBAI = void 0;
var ethers_1 = require("ethers");
var chainInfo_1 = require("./chainInfo");
exports.DENOTA_APIURL_REMOTE_MUMBAI = "https://klymr.me/graph-mumbai";
// import CheqRegistrar from "./abis/CheqRegistrar.sol/CheqRegistrar.json";
exports.DENOTA_SUPPORTED_CHAIN_IDS = [80001];
var state = {
    blockchainState: {
        account: "",
        registrar: null,
        registrarAddress: "",
        signer: null,
        directPayAddress: "",
        chainId: 0,
    },
};
function setProvider(web3Connection) {
    return __awaiter(this, void 0, void 0, function () {
        var provider, signer, account, chainId, contractMapping, registrar;
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
                        registrar = new ethers_1.ethers.Contract(contractMapping.cheq, "", signer);
                        state.blockchainState = {
                            signer: signer,
                            account: account,
                            registrarAddress: contractMapping.cheq,
                            registrar: registrar,
                            directPayAddress: contractMapping.directPayModule,
                            chainId: chainId,
                        };
                    }
                    return [2 /*return*/];
            }
        });
    });
}
exports.setProvider = setProvider;
function write(_a) {
    var module = _a.module;
    if (module.moduleName == "Direct") {
    }
    else {
    }
}
exports.write = write;
function approveToken(_a) { }
exports.approveToken = approveToken;
function sendDirectPayment(_a) {
    var recipient = _a.recipient, token = _a.token, amount = _a.amount, note = _a.note, file = _a.file;
}
exports.sendDirectPayment = sendDirectPayment;
function sendDirectPayInvoice(_a) {
    var recipient = _a.recipient, token = _a.token, amount = _a.amount, note = _a.note, file = _a.file;
}
exports.sendDirectPayInvoice = sendDirectPayInvoice;
function fundDirectPayInvoice(_a) { }
exports.fundDirectPayInvoice = fundDirectPayInvoice;
function sendReversiblePayent(_a) { }
exports.sendReversiblePayent = sendReversiblePayent;
function sendReversibleInvoice(_a) { }
exports.sendReversibleInvoice = sendReversibleInvoice;
function reversePayment(_a) { }
exports.reversePayment = reversePayment;
function sendMilestoneInvoice(_a) { }
exports.sendMilestoneInvoice = sendMilestoneInvoice;
function sendMilestonePayment(_a) { }
exports.sendMilestonePayment = sendMilestonePayment;
function sendBatchPayment(_a) { }
exports.sendBatchPayment = sendBatchPayment;
function sendBatchPaymentFromCSV(csv) { }
exports.sendBatchPaymentFromCSV = sendBatchPaymentFromCSV;
function fetchNotas(query) { }
exports.fetchNotas = fetchNotas;
