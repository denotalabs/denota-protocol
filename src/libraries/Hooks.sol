// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {IHooks} from "../interfaces/IHooks.sol";

// TODO look at univ4 library, callHook is implemented differently. Uses assembly to make the call AND bubbles it up.
library Hooks {
    using Hooks for IHooks;

    error HookFailure();
    error InvalidHookResponse();

    function callHook(IHooks self, bytes4 selector, bytes memory data) internal returns (uint256) {
        (, bytes memory result) = address(self).call(abi.encodePacked(selector, data));
        
        if (result.length < 36) {
            // If the result length is less than 36 bytes, it is an invalid return value
            if (result.length == 0) revert HookFailure();

            // The error message is ABI-encoded as a string
            assembly {
                let returndata_size := mload(result)
                revert(add(32, result), returndata_size)
            }
        }
        // Extract the returned selector and fee
        bytes4 returnedSelector;
        uint256 hookFee;
        assembly {
            // Load the first 4 bytes (selector) from the result
            returnedSelector := mload(add(result, 32))
            // Load the next 32 bytes (uint256 fee) from the result
            hookFee := mload(add(result, 64))
        }

        if (returnedSelector != selector) revert InvalidHookResponse();

        return hookFee;
    }

/**
    function callHook(IHooks self, bytes memory data) internal returns (bytes memory result) {
        bool success;
        assembly ("memory-safe") {
            success := call(gas(), self, 0, add(data, 0x20), mload(data), 0, 0)
        }
        // Revert with FailedHookCall, containing any error message to bubble up
        // if (!success) Wrap__FailedHookCall.selector.bubbleUpAndRevertWith(address(self));

        // The call was successful, fetch the returned data
        assembly ("memory-safe") {
            // allocate result byte array from the free memory pointer
            result := mload(0x40)
            // store new free memory pointer at the end of the array padded to 32 bytes
            mstore(0x40, add(result, and(add(returndatasize(), 0x3f), not(0x1f))))
            // store length in memory
            mstore(result, returndatasize())
            // copy return data to result
            returndatacopy(add(result, 0x20), 0, returndatasize())
        }

        // Length must be at least 32 to contain the selector. Check expected selector and returned selector match.
        if (result.length < 32) { //  || result.parseSelector() != data.parseSelector()
            // InvalidHookResponse.selector.revertWith();
        }
    }
 */
    function beforeWrite(IHooks self, IHooks.NotaState memory nota, uint256 instant, bytes calldata hookData)
        internal
        returns (uint256)
    {
        return callHook(self, IHooks.beforeWrite.selector, abi.encode(msg.sender, nota, instant, hookData));
    }

    function beforeTransfer(IHooks self, IHooks.NotaState memory nota, address to, bytes memory hookData)
        internal
        returns (uint256)
    {
        return callHook(self, IHooks.beforeTransfer.selector, abi.encode(msg.sender, nota, to, hookData));
    }

    function beforeFund(
        IHooks self,
        IHooks.NotaState memory nota,
        uint256 amount,
        uint256 instant,
        bytes calldata hookData
    ) internal returns (uint256) {
        return callHook(self, IHooks.beforeFund.selector, abi.encode(msg.sender, nota, amount, instant, hookData));
    }

    function beforeCash(IHooks self, IHooks.NotaState memory nota, address to, uint256 amount, bytes calldata hookData)
        internal
        returns (uint256)
    {
        return callHook(self, IHooks.beforeCash.selector, abi.encode(msg.sender, nota, to, amount, hookData));
    }

    function beforeApprove(IHooks self, IHooks.NotaState memory nota, address to) internal returns (uint256) {
        return callHook(self, IHooks.beforeApprove.selector, abi.encode(msg.sender, nota, to));
    }

    function beforeBurn(IHooks self, IHooks.NotaState memory nota) internal {
        (, bytes memory result) =
            address(self).call(abi.encodePacked(IHooks.beforeBurn.selector, abi.encode(msg.sender, nota)));
        if (result.length < 4) revert HookFailure(); // 4 bytes for selector

        bytes4 returnedSelector;
        assembly {
            returnedSelector := mload(add(result, 32))
        } // Extract the returned selector

        if (returnedSelector != IHooks.beforeBurn.selector) revert InvalidHookResponse();
    }

    function beforeUpdate(IHooks self, IHooks.NotaState memory nota, bytes calldata hookData)
        internal
        returns (uint256)
    {
        return callHook(self, IHooks.beforeUpdate.selector, abi.encode(msg.sender, nota, hookData));
    }

    function beforeTokenURI(IHooks self, IHooks.NotaState memory nota)
        internal
        view
        returns (string memory, string memory)
    {
        (bytes4 returnedSelector, string memory hookAttributes, string memory hookKeys) =
            self.beforeTokenURI(msg.sender, nota);
        if (returnedSelector != IHooks.beforeTokenURI.selector) revert InvalidHookResponse();

        return (hookAttributes, hookKeys);
    }
}
