// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IHooks} from "../../src/interfaces/IHooks.sol";

contract MockHook is IHooks {
    uint256 public fee;
    bool public fail;

    function setFee(uint256 _fee) external {
        fee = _fee;
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function setFail(bool _fail) external {
        fail = _fail;
    }

    function beforeWrite(address, IHooks.NotaState memory, uint256, bytes calldata)
        external
        view
        returns (bytes4, uint256)
    {
        if (fail) revert("MockHook: FAIL");
        return (IHooks.beforeWrite.selector, fee);
    }

    function beforeTransfer(address, IHooks.NotaState memory, address, bytes calldata)
        external
        view
        returns (bytes4, uint256)
    {
        if (fail) revert("MockHook: FAIL");
        return (IHooks.beforeTransfer.selector, fee);
    }

    function beforeFund(address, IHooks.NotaState memory, uint256, uint256, bytes calldata)
        external
        view
        returns (bytes4, uint256)
    {
        if (fail) revert("MockHook: FAIL");
        return (IHooks.beforeFund.selector, fee);
    }

    function beforeCash(address, IHooks.NotaState memory, address, uint256, bytes calldata)
        external
        view
        returns (bytes4, uint256)
    {
        if (fail) revert("MockHook: FAIL");
        return (IHooks.beforeCash.selector, fee);
    }

    function beforeApprove(address, IHooks.NotaState memory, address) external view returns (bytes4, uint256) {
        if (fail) revert("MockHook: FAIL");
        return (IHooks.beforeApprove.selector, fee);
    }

    function beforeBurn(address, IHooks.NotaState memory) external view returns (bytes4) {
        if (fail) revert("MockHook: FAIL");
        return IHooks.beforeBurn.selector;
    }

    function beforeUpdate(address, IHooks.NotaState memory, bytes calldata) external view returns (bytes4, uint256) {
        if (fail) revert("MockHook: FAIL");
        return (IHooks.beforeUpdate.selector, fee);
    }

    function beforeTokenURI(address, IHooks.NotaState memory)
        external
        view
        returns (bytes4, string memory, string memory)
    {
        if (fail) revert("MockHook: FAIL");
        return (IHooks.beforeTokenURI.selector, "", "");
    }

    function notaBytes(uint256) external view override returns (bytes memory) {
        if (fail) revert("MockHook: FAIL");
        return "";
    }
}
