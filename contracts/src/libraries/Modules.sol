// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {INotaModule} from "../interfaces/INotaModule.sol";
// import {IHooks} from "../interfaces/IHooks.sol";
// import {FeeLibrary} from "../libraries/FeeLibrary.sol";

/// @notice V4 decides whether to invoke specific hooks by inspecting the leading bits of the address that
/// the hooks contract is deployed to.
/// For example, a hooks contract deployed to address: 0x9000000000000000000000000000000000000000
/// has leading bits '1001' which would cause the 'before initialize' and 'after modify position' hooks to be used.
// Note: 1001000000000000000000000000000000000000000000000000000000000000
// TODO: check how many leading bits is reasonable to mine (5hex at most? => 20bits) [IWTFCA = 12bits = 3hex]
library Hooks {
    // using FeeLibrary for uint24;
    uint256 internal constant BEFORE_INITIALIZE_FLAG = 1 << 159;
    uint256 internal constant AFTER_INITIALIZE_FLAG = 1 << 158;
    uint256 internal constant BEFORE_WRITE_FLAG = 1 << 157;
    uint256 internal constant AFTER_WRITE_FLAG = 1 << 156;
    uint256 internal constant BEFORE_TRANSFER_FLAG = 1 << 155;
    uint256 internal constant AFTER_TRANSFER_FLAG = 1 << 154;
    uint256 internal constant BEFORE_FUND_FLAG = 1 << 153;
    uint256 internal constant AFTER_FUND_FLAG = 1 << 152;
    uint256 internal constant BEFORE_CASH_FLAG = 1 << 151;
    uint256 internal constant AFTER_CASH_FLAG = 1 << 150;

    struct Calls {
        bool beforeInitialize;
        bool afterInitialize;
        bool beforeWrite;
        bool afterWrite;
        bool beforeTransfer;
        bool afterTransfer;
        bool beforeFund;
        bool afterFund;
        bool beforeCash;
        bool afterCash;
    }


    /// @notice Thrown if the address will not lead to the specified hook calls being called
    /// @param module The address of the hooks contract
    error ModuleAddressNotValid(address module);

    /// @notice Hook did not return its selector
    error InvalidModuleResponse();

    /// @notice Utility function intended to be used in hook constructors to ensure
    /// the deployed hooks address causes the intended hooks to be called
    /// @param calls The hooks that are intended to be called
    /// @dev calls param is memory as the function will be called from constructors
    function validateHookAddress(INotaModule self, Calls memory calls) internal pure {
        if (
            calls.beforeInitialize != shouldCallBeforeInitialize(self)
                || calls.afterInitialize != shouldCallAfterInitialize(self)
                || calls.beforeWrite != shouldCallBeforeWrite(self)
                || calls.afterWrite != shouldCallAfterWrite(self)
                || calls.beforeTransfer != shouldCallBeforeTransfer(self)
                || calls.afterTransfer != shouldCallAfterTransfer(self)
                || calls.beforeFund != shouldCallBeforeFund(self)
                || calls.afterFund != shouldCallAfterFund(self)
                || calls.beforeCash != shouldCallBeforeCash(self)
                || calls.afterCash != shouldCallAfterCash(self)
        ) {
            revert ModuleAddressNotValid(address(self));
        }
    }

    // / @notice Ensures that the hook address includes at least one hook flag or dynamic fees, or is the 0 address
    // / @param hook The hook to verify
    // function isValidHookAddress(INotaModule hook, uint24 fee) internal pure returns (bool) {
    //     // If there is no hook contract set, then fee cannot be dynamic and there cannot be a hook fee on swap or withdrawal.
    //     return address(hook) == address(0)
    //         ? !fee.isDynamicFee() && !fee.hasHookSwapFee() && !fee.hasHookWithdrawFee()
    //         : (  // NOTE: `uint160(address(hook)) >= AFTER_DONATE_FLAG` is the smallest integer flag. If address is greater then there are fees of some kind
    //             uint160(address(hook)) >= AFTER_CASH_FLAG || fee.isDynamicFee() || fee.hasHookSwapFee()
    //                 || fee.hasHookWithdrawFee()
    //         );
    // }


    function shouldCallBeforeInitialize(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & BEFORE_INITIALIZE_FLAG != 0;
    }

    function shouldCallAfterInitialize(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & AFTER_INITIALIZE_FLAG != 0;
    }

    function shouldCallBeforeWrite(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & BEFORE_WRITE_FLAG != 0;
    }

    function shouldCallAfterWrite(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & AFTER_WRITE_FLAG != 0;
    }

    function shouldCallBeforeTransfer(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & BEFORE_TRANSFER_FLAG != 0;
    }

    function shouldCallAfterTransfer(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & AFTER_TRANSFER_FLAG != 0;
    }

    function shouldCallBeforeFund(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & BEFORE_FUND_FLAG != 0;
    }

    function shouldCallAfterFund(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & AFTER_FUND_FLAG != 0;
    }

    function shouldCallBeforeCash(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & BEFORE_CASH_FLAG != 0;
    }

    function shouldCallAfterCash(INotaModule self) internal pure returns (bool) {
        return uint256(uint160(address(self))) & AFTER_CASH_FLAG != 0;
    }}
