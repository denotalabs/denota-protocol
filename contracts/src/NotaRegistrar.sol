
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/Base64.sol";
import {IHooks} from "./interfaces/IHooks.sol";
import {INotaRegistrar} from "./interfaces/INotaRegistrar.sol";
import  "./RegistrarGov.sol";
import  "./ERC4906.sol";

/**
 * DISCLAIMER OF LIABILITY
 * =======================
 * Denota Protocol is provided "as is", without warranty of any kind. Use at your own risk.
 * The author(s) of this smart contract and Denota Protocol shall not be liable for any damages or losses caused by the use or inability to use this protocol.
 * This protocol has NOT undergone a formal security audit. As such, there may be risks of vulnerabilities or bugs that could lead to financial loss. 
 * Users are advised to carefully assess their risk tolerance and only interact with this protocol if they understand and accept these risks.
 * This protocol is experimental and should not be considered as a fully secure or reliable financial service. 
 * We strongly recommend reviewing the source code and conducting thorough testing before committing any value or conducting transactions through this protocol.
 * =======================
 * @title Denota Protocol
 * @author Almaraz.eth
 * @custom:description Denota Protocol (beta)- a token agreement protocol.
 * The core primitive is the Nota, an NFT that represents the ownership of underlying assets and issued by the NotaRegistrar.
 * Each Nota can escrow ERC20s and references a hook which enforces the rules of both the Nota's ownership and it's escrowed funds.
 * 
 * HOW TO USE:
 * The main relevant functions for most Notas will be WTFCAT or Write (mint), Transfer, Fund, Cash, Approve, and TokenURI.
 * Writing a Nota requires approval of: your tokens so they can be escrowed, and both hook and tokens you wish to use 
 * * NOTE The `hookData` parameter are special arguments needed from the hook being referenced. Please refer to the hook for what (if any) bytes argument format it is expecting and use an abi.encode website to assist.
 * Whitelisting of hooks and tokens is controlled by the deployer (me, for now) but only apply when creating new Notas. It's permissioned for safety purposes and is the only thing the NotaRegistrar's owner controls.
 * Notas are compatible with NFT marketplaces, and provide detailed and trustable metadata for display.
 * HOW TO PROFIT:
 * Each hook can charge a fee every time a Nota that references it is used. Registering your account to a hook allows you to collect the fees the hook generates
 */

contract NotaRegistrar is ERC4906, INotaRegistrar, RegistrarGov {
    using SafeERC20 for IERC20;
    
    mapping(IHooks hook => mapping(address token => uint256 revenue)) private _hookRevenue;
    mapping(uint256 notaId => Nota) private _notas;
    uint256 public nextId;

    modifier exists(uint256 notaId) {
        if (_ownerOf(notaId) == address(0)) revert NonExistent();
        _;
    }

    constructor(address newOwner) ERC4906("Denota Protocol (beta)", "NOTA") {
        transferOwnership(newOwner);  // Needed when using create2
    }

    /**
     * @notice Mints a Nota and transfers tokens
     * @dev Requires hook & currency whitelisted and `owner` != address(0). Transfers instant/escrow tokens from msg.sender, sends instant tokens to `owner`
     */
    function write(address currency, uint256 escrowed, uint256 instant, address owner, IHooks hook, bytes calldata hookData) public payable returns (uint256) {
        require(validWrite(hook, currency), "INVALID_WRITE");
        uint256 hookFee = hook.beforeWrite(msg.sender, nextId, currency, escrowed, owner, instant, hookData);

        _transferTokens(currency, owner, escrowed, instant, hookFee);
        _mint(owner, nextId);
        _notas[nextId] = Nota(escrowed, currency, hook);
        
        _hookRevenue[hook][currency] += hookFee;

        emit Written(msg.sender, nextId, currency, escrowed, hook, instant, hookFee, hookData);
        unchecked { return nextId++; }
    }

    /**
     * @dev Enforces the transfer requirements (isApprovedOrOwner) before transferHook is called
     */
    function transferFrom(address from, address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) exists(notaId) {
        _transferHookTakeFee(from, to, notaId, abi.encode(""));
        _transfer(from, to, notaId);
        emit MetadataUpdate(notaId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 notaId,
        bytes memory hookData
    ) public override(ERC721, IERC721, INotaRegistrar) {
        _transferHookTakeFee(from, to, notaId, hookData);
        _safeTransfer(from, to, notaId, abi.encode(""));
        emit MetadataUpdate(notaId);
    }

    /**
     * @notice Adds to the escrowed amount of a Nota
     * @dev No requirements except what the hook enforces
     */
    function fund(uint256 notaId, uint256 amount, uint256 instant, bytes calldata hookData) public payable exists(notaId) {
        Nota memory nota = notaInfo(notaId);
        address notaOwner = ownerOf(notaId);
        uint256 hookFee = nota.hook.beforeFund(msg.sender, notaId, nota.escrowed, notaOwner, amount, instant, hookData);

        _transferTokens(nota.currency, notaOwner, amount, instant, hookFee);
        _notas[notaId].escrowed += amount;
        _hookRevenue[nota.hook][nota.currency] += hookFee;

        emit Funded(msg.sender, notaId, amount, instant, hookFee, hookData);
        emit MetadataUpdate(notaId);
    }

    /**
     * @notice Removes from the escrowed amount of a Nota
     * @dev No requirements except what the hook enforces
     */
    function cash(uint256 notaId, uint256 amount, address to, bytes calldata hookData) public payable exists(notaId) {
        Nota memory nota = notaInfo(notaId);
        uint256 hookFee = nota.hook.beforeCash(msg.sender, notaId, nota.escrowed, ownerOf(notaId), to, amount, hookData);

        _notas[notaId].escrowed -= amount;
        _unescrowTokens(nota.currency, to, amount - hookFee);  // hookFee stays in escrow. Should `amount` include the hookFee or have it removed on after?
        _hookRevenue[nota.hook][nota.currency] += hookFee;

        emit Cashed(msg.sender, notaId, to, amount, hookFee, hookData);
        emit MetadataUpdate(notaId);
    }

    function approve(address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) exists(notaId) {
        Nota memory nota = notaInfo(notaId);
        uint256 hookFee = nota.hook.beforeApprove(msg.sender, notaId, nota.escrowed, ownerOf(notaId), to);

        _notas[notaId].escrowed -= hookFee;
        _hookRevenue[nota.hook][nota.currency] += hookFee;

        ERC721.approve(to, notaId);  // Keeps checks is owner or operator && to != owner
        emit Approved(msg.sender, notaId, hookFee);
        emit MetadataUpdate(notaId);
    }

    function burn(uint256 notaId) public exists(notaId) {
        Nota memory nota = notaInfo(notaId);
        require(_isApprovedOrOwner(msg.sender, notaId), "NOT_APPROVED_OR_OWNER");

        nota.hook.beforeBurn(msg.sender, notaId, nota.escrowed, ownerOf(notaId));
        
        _hookRevenue[nota.hook][nota.currency] += nota.escrowed;
        delete _notas[notaId];
        _burn(notaId);
    }

    function tokenURI(uint256 notaId) public view override exists(notaId) returns (string memory) {
        Nota memory nota = notaInfo(notaId);
        (string memory hookAttributes, string memory hookKeys) = nota.hook.beforeTokenURI(notaId);
        
        return string(
                abi.encodePacked(
                    "data:application/json;base64,", 
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"attributes":[{"trait_type":"ERC20","value":"',
                                Strings.toHexString(nota.currency),
                                '"},{"trait_type":"Amount","display_type":"number","value":',
                                Strings.toString(nota.escrowed),
                                '},{"trait_type":"Escrow Conditions","value":"', // Wrapper vs Hook vs Conditions vs Conditions Contract
                                Strings.toHexString(address(nota.hook)),
                                '"}',
                                hookAttributes,  // of form: ',{"trait_type":"<trait>","value":"<value>"}'
                                ']',
                                hookKeys, // of form: ',{"<key>":"<value>"}
                                '}'
                            )
                        )
                    )
                )
            );
    }

    function contractURI() public view returns (string memory) {
        return string.concat("data:application/json;utf8,", _contractURI);
    }

    /*//////////////////////// HELPERS ///////////////////////////*/
    function _transferHookTakeFee(
        address from,
        address to,
        uint256 notaId,
        bytes memory hookData
    ) private {
        require(_isApprovedOrOwner(msg.sender, notaId), "NOT_APPROVED_OR_OWNER");

        if (hookData.length == 0) hookData = abi.encode("");
        Nota memory nota = notaInfo(notaId);
        address owner = ownerOf(notaId);
        uint256 hookFee = nota.hook.beforeTransfer(msg.sender, notaId, nota.escrowed, owner, from, to, hookData);

        _notas[notaId].escrowed -= hookFee;
        _hookRevenue[nota.hook][nota.currency] += hookFee;  // NOTE could do this unchecked
        emit Transferred(msg.sender, notaId, hookFee, hookData);
    }

    function _instantTokens(address currency, address to, uint256 instant) private {
        if (instant > 0) IERC20(currency).safeTransferFrom(msg.sender, to, instant);
    }
    function _escrowTokens(address currency, uint256 toEscrow) private {
        if (toEscrow > 0) IERC20(currency).safeTransferFrom(msg.sender, address(this), toEscrow);
    }
    function _unescrowTokens(address currency, address to, uint256 amount) private {
        if (amount > 0) IERC20(currency).safeTransfer(to, amount);
    }
    function _transferTokens(
        address currency,
        address recipient,
        uint256 escrowed,
        uint256 instant,
        uint256 hookFee
    ) private {
        uint256 toEscrow = escrowed + hookFee;
        _escrowTokens(currency, toEscrow);
        _instantTokens(currency, recipient, instant);
    }

    /**
     * @notice Updates the metadata of a Nota when hook state changes without calling the registrar
     */
    function metadataUpdate(uint256 notaId) external {
        require(msg.sender == address(_notas[notaId].hook), "NOT_MODULE");
        emit MetadataUpdate(notaId);
    }

    function hookWithdraw(address token, uint256 amount, address to) external {
        _hookRevenue[IHooks(msg.sender)][token] -= amount;  // reverts on underflow
        _unescrowTokens(token, to, amount);
    }

    function hookRevenue(IHooks hook, address currency) external view returns(uint256) {
        return _hookRevenue[hook][currency];
    }

    function notaInfo(
        uint256 notaId
    ) public view exists(notaId) returns (Nota memory) {
        return _notas[notaId];
    }

    function notaEscrowed(uint256 notaId) public view exists(notaId) returns (uint256) {
        return _notas[notaId].escrowed;
    }

    function notaCurrency(uint256 notaId) public view exists(notaId) returns (address) {
        return _notas[notaId].currency;
    }

    function notaHook(uint256 notaId) public view exists(notaId) returns (IHooks) {
        return _notas[notaId].hook;
    }
}