// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC7799Module.sol";
import "../ERC7799Core.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title StateTransitionModule
 * @dev Core state transition logic for ERC7799 system
 * @author Jimmy Salau
 * @notice Manages all state transitions while maintaining core invariants
 */
contract StateTransitionModule is IERC7799Module, ReentrancyGuard {
    using SafeMath for uint256;
    
    ERC7799Core private immutable _core;
    
    // Custom errors
    error UnauthorizedCaller();
    error InvalidAddress();
    error InsufficientBalance();
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferFrom(address indexed spender, address indexed from, address indexed to, uint256 value);

    constructor(address coreAddress) {
        if(coreAddress == address(0)) revert InvalidAddress();
        _core = ERC7799Core(coreAddress);
    }

    // Module interface implementation
    function moduleName() external pure override returns (string memory) {
        return "StateTransitionModule";
    }

    function moduleVersion() external pure override returns (uint256) {
        return 1_00; // Semantic versioning 1.0.0
    }

    function requiredCoreVersion() external pure override returns (uint256) {
        return 1_00; // Requires core v1.0.0+
    }

    /**
     * @dev Core state transition function for token transfers
     * @param from Sender address
     * @param to Recipient address
     * @param amount Transfer amount
     */
    function transfer(address from, address to, uint256 amount) external nonReentrant {
        if(msg.sender != address(_core)) revert UnauthorizedCaller();
        
        _validateTransfer(from, to, amount);
        
        _core.updateBalance(from, _core.balanceOf(from).sub(amount));
        _core.updateBalance(to, _core.balanceOf(to).add(amount));
        
        emit Transfer(from, to, amount);
    }

    /**
     * @dev Allowance-based state transition
     * @param spender Approved address
     * @param from Source address
     * @param to Recipient address
     * @param amount Transfer amount
     */
    function transferFrom(address spender, address from, address to, uint256 amount) external nonReentrant {
        if(msg.sender != address(_core)) revert UnauthorizedCaller();
        
        _validateTransfer(from, to, amount);
        
        uint256 currentAllowance = _core.allowance(from, spender);
        require(currentAllowance >= amount, "Allowance exceeded");
        
        _core.updateAllowance(from, spender, currentAllowance.sub(amount));
        _core.updateBalance(from, _core.balanceOf(from).sub(amount));
        _core.updateBalance(to, _core.balanceOf(to).add(amount));
        
        emit TransferFrom(spender, from, to, amount);
    }

    /**
     * @dev Universal transfer validation
     */
    function _validateTransfer(address from, address to, uint256 amount) internal view {
        if(from == address(0) || to == address(0)) revert InvalidAddress();
        if(_core.balanceOf(from) < amount) revert InsufficientBalance();
        if(amount == 0) revert("Zero amount");
    }
}