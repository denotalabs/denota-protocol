// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;
import "openzeppelin/utils/Context.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/INotaFees.sol";

abstract contract NotaFees is Context, INotaFees {
    using SafeERC20 for IERC20;
    mapping(address => mapping(address => uint256)) internal _moduleRevenue; // [module][token] => revenue
    mapping(address => uint24) internal _moduleFees;  // as percentage // TODO Have this be set as the fee mapping

    function setFees(uint24 fees) external {
        _moduleFees[_msgSender()] = fees;
        emit FeeSet(_msgSender(), fees);
    }
    function moduleWithdraw(address token, uint256 amount, address to) external {
        require(_moduleRevenue[_msgSender()][token] >= amount, "INSUF_FUNDS");
        unchecked {
            _moduleRevenue[_msgSender()][token] -= amount;
        }
        IERC20(token).safeTransferFrom(address(this), to, amount);
    }

}