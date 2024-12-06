// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/utils/Base64.sol";
import {INotaRegistrar} from "./interfaces/INotaRegistrar.sol";
import {IHooks} from "./interfaces/IHooks.sol";
import {Hooks} from "./libraries/Hooks.sol";
import "./RegistrarGov.sol";
import "./ERC4906.sol";

/**
 * @title Denota Protocol
 * @author Almaraz.eth
 */
contract NotaRegistrar is ERC4906, INotaRegistrar, RegistrarGov, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Hooks for IHooks;

    mapping(uint256 notaId => Nota) private _notas;
    uint256 public nextId;

    modifier exists(uint256 notaId) {
        if (_ownerOf(notaId) == address(0)) revert NonExistent();
        _;
    }

    constructor(address newOwner) ERC4906("Denota-Protocol-beta-NFT", "NOTA") {
        transferOwnership(newOwner); // Needed when using create2
        nextId = 1;
    }

    /// @inheritdoc INotaRegistrar
    function write(
        address currency,
        uint256 escrowed,
        uint256 instant,
        address owner,
        IHooks hooks,
        bytes calldata hookData
    ) external payable nonReentrant returns (uint256) {
        uint256 hookFee =
            hooks.beforeWrite(IHooks.NotaState(nextId, currency, escrowed, owner, address(0)), instant, hookData);

        _transferTokens(currency, owner, escrowed, instant, hookFee);
        _mint(owner, nextId);
        _notas[nextId] = Nota(escrowed, currency, hooks);

        _hookRevenue[hooks][currency] += hookFee;

        emit Written(msg.sender, nextId, currency, escrowed, hooks, instant, hookFee, hookData);
        unchecked {
            return nextId++;
        }
    }

    /// @inheritdoc INotaRegistrar
    function transferFrom(address from, address to, uint256 notaId)
        public
        override(ERC721, IERC721, INotaRegistrar)
        nonReentrant
    {
        _transferHookTakeFee(to, notaId, abi.encode(""));
        _transfer(from, to, notaId);
        emit MetadataUpdate(notaId);
    }

    /// @inheritdoc INotaRegistrar
    function safeTransferFrom(address from, address to, uint256 notaId, bytes memory hookData)
        public
        override(ERC721, IERC721, INotaRegistrar)
        nonReentrant
    {
        _transferHookTakeFee(to, notaId, hookData);
        _safeTransfer(from, to, notaId, abi.encode(""));
        emit MetadataUpdate(notaId);
    }

    /// @inheritdoc INotaRegistrar
    function fund(uint256 notaId, uint256 amount, uint256 instant, bytes calldata hookData)
        external
        payable
        nonReentrant
    {
        Nota memory nota = notaInfo(notaId);
        address notaOwner = ownerOf(notaId);
        uint256 hookFee = nota.hooks.beforeFund(
            IHooks.NotaState(notaId, nota.currency, nota.escrowed, notaOwner, getApproved(notaId)),
            amount,
            instant,
            hookData
        );

        _transferTokens(nota.currency, notaOwner, amount, instant, hookFee);
        _notas[notaId].escrowed += amount;
        _hookRevenue[nota.hooks][nota.currency] += hookFee;

        emit Funded(msg.sender, notaId, amount, instant, hookFee, hookData);
        emit MetadataUpdate(notaId);
    }

    /// @inheritdoc INotaRegistrar
    function cash(uint256 notaId, uint256 amount, address to, bytes calldata hookData) external payable nonReentrant {
        Nota memory nota = notaInfo(notaId);
        uint256 hookFee = nota.hooks.beforeCash(
            IHooks.NotaState(notaId, nota.currency, nota.escrowed, ownerOf(notaId), getApproved(notaId)),
            to,
            amount,
            hookData
        );

        _notas[notaId].escrowed -= amount;
        _unescrowTokens(nota.currency, to, amount - hookFee); // hookFee stays in escrow. Should `amount` include the hookFee or have it removed on after?
        _hookRevenue[nota.hooks][nota.currency] += hookFee;

        emit Cashed(msg.sender, notaId, to, amount, hookFee, hookData);
        emit MetadataUpdate(notaId);
    }

    /// @inheritdoc INotaRegistrar
    function approve(address to, uint256 notaId) public override(ERC721, IERC721, INotaRegistrar) nonReentrant {
        Nota memory nota = notaInfo(notaId);
        uint256 hookFee = nota.hooks.beforeApprove(
            IHooks.NotaState(notaId, nota.currency, nota.escrowed, ownerOf(notaId), getApproved(notaId)), to
        );

        _notas[notaId].escrowed -= hookFee;
        _hookRevenue[nota.hooks][nota.currency] += hookFee;

        ERC721.approve(to, notaId); // Keeps check of is owner OR operator AND to != owner
        emit Approved(msg.sender, notaId, hookFee);
        emit MetadataUpdate(notaId);
    }

    /// @inheritdoc INotaRegistrar
    function burn(uint256 notaId) external nonReentrant {
        Nota memory nota = notaInfo(notaId);
        require(_isApprovedOrOwner(msg.sender, notaId), "NOT_APPROVED_OR_OWNER");

        nota.hooks.beforeBurn(
            IHooks.NotaState(notaId, nota.currency, nota.escrowed, ownerOf(notaId), getApproved(notaId))
        );

        _hookRevenue[nota.hooks][nota.currency] += nota.escrowed;
        delete _notas[notaId];
        _burn(notaId);
        emit Burned(msg.sender, notaId);
    }

    /// @inheritdoc INotaRegistrar
    function update(uint256 notaId, bytes calldata hookData) external nonReentrant {
        Nota memory nota = notaInfo(notaId);

        uint256 hookFee = nota.hooks.beforeUpdate(
            IHooks.NotaState(notaId, nota.currency, nota.escrowed, ownerOf(notaId), getApproved(notaId)),
            hookData
        );

        _notas[notaId].escrowed -= hookFee;
        _hookRevenue[nota.hooks][nota.currency] += hookFee;

        emit MetadataUpdate(notaId);
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 notaId) public view override returns (string memory) {
        Nota memory nota = notaInfo(notaId);
        (string memory hookAttributes, string memory hookKeys) = nota.hooks.beforeTokenURI(
            IHooks.NotaState(notaId, nota.currency, nota.escrowed, ownerOf(notaId), getApproved(notaId))
        );

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
                            '},{"trait_type":"Hook Contract","value":"',
                            Strings.toHexString(address(nota.hooks)),
                            '"}',
                            hookAttributes, // of form: ',{"trait_type":"<trait>","value":"<value>"}'
                            "]",
                            hookKeys, // of form: ',{"<key>":"<value>"}
                            "}"
                        )
                    )
                )
            )
        );
    }

    /*//////////////////////// HELPERS ///////////////////////////*/
    function _transferHookTakeFee(address to, uint256 notaId, bytes memory hookData) private {
        require(_isApprovedOrOwner(msg.sender, notaId), "NOT_APPROVED_OR_OWNER"); // Can't use builtin transfer since check and _transfer is atomic

        if (hookData.length == 0) hookData = abi.encode(""); // TODO is this necessary?
        Nota memory nota = notaInfo(notaId);
        address owner = ownerOf(notaId);
        uint256 hookFee = nota.hooks.beforeTransfer(
            IHooks.NotaState(notaId, nota.currency, nota.escrowed, owner, getApproved(notaId)), to, hookData
        );

        _notas[notaId].escrowed -= hookFee;
        _hookRevenue[nota.hooks][nota.currency] += hookFee; // NOTE could do this unchecked
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

    function _transferTokens(address currency, address recipient, uint256 escrowed, uint256 instant, uint256 hookFee)
        private
    {
        uint256 toEscrow = escrowed + hookFee;
        _escrowTokens(currency, toEscrow);
        _instantTokens(currency, recipient, instant); // TODO pull out the function here?
            // if (instant > 0) IERC20(currency).safeTransferFrom(msg.sender, to, instant);
    }

    /*//////////////////////// VIEW FUNCTIONS ///////////////////////////*/
    /// @inheritdoc INotaRegistrar
    function notaInfo(uint256 notaId) public view exists(notaId) returns (Nota memory) {
        return _notas[notaId];
    }

    /// @inheritdoc INotaRegistrar
    function notaEscrowed(uint256 notaId) public view exists(notaId) returns (uint256) {
        return _notas[notaId].escrowed;
    }

    /// @inheritdoc INotaRegistrar
    function notaCurrency(uint256 notaId) public view exists(notaId) returns (address) {
        return _notas[notaId].currency;
    }

    /// @inheritdoc INotaRegistrar
    function notaHooks(uint256 notaId) public view exists(notaId) returns (IHooks) {
        return _notas[notaId].hooks;
    }

    /// @inheritdoc INotaRegistrar
    function notaData(uint256 notaId) public view exists(notaId) returns (Nota memory, bytes memory) {
        Nota memory nota = _notas[notaId];
        bytes memory data = nota.hooks.notaBytes(notaId);
        return (nota, data);
    }

    /// @inheritdoc INotaRegistrar
    function notaStateData(uint256 notaId) public view exists(notaId) returns (IHooks.NotaState memory, bytes memory) {
        Nota memory nota = _notas[notaId];
        bytes memory data = nota.hooks.notaBytes(notaId);
        return (
                IHooks.NotaState(notaId, nota.currency, nota.escrowed, ownerOf(notaId), getApproved(notaId)),
                data
            );
    }
}
