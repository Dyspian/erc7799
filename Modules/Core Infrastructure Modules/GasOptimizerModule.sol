// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC7799Module.sol";
import "../ERC7799Core.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title GasOptimizerModule
 * @dev Dynamic gas price optimization using EMA calculations
 * @author Jimmy Salau
 * @notice Provides real-time gas fee recommendations and fee market adjustments
 */
contract GasOptimizerModule is IERC7799Module, ReentrancyGuard {
    ERC7799Core private immutable _core;
    
    // EMA calculation parameters
    uint256 private _emaBaseFee;
    uint256 private _alphaNumerator;
    uint256 private _alphaDenominator;
    
    // Precision multiplier for fixed-point math
    uint256 private constant PRECISION = 1e18;
    
    // Events
    event EMAUpdated(uint256 newEMA, uint256 blockNumber);
    event AlphaParametersUpdated(uint256 numerator, uint256 denominator);
    
    // Errors
    error InvalidCoreAddress();
    error UnauthorizedGovernance();
    error InvalidAlphaParameters();

    constructor(
        address coreAddress,
        uint256 initialEMA,
        uint256 alphaNumerator,
        uint256 alphaDenominator
    ) {
        if(coreAddress == address(0)) revert InvalidCoreAddress();
        if(alphaDenominator <= alphaNumerator) revert InvalidAlphaParameters();
        
        _core = ERC7799Core(coreAddress);
        _emaBaseFee = initialEMA;
        _alphaNumerator = alphaNumerator;
        _alphaDenominator = alphaDenominator;
    }

    // Module interface implementation
    function moduleName() external pure override returns (string memory) {
        return "GasOptimizerModule";
    }

    function moduleVersion() external pure override returns (uint256) {
        return 1_00; // Semantic versioning 1.0.0
    }

    function requiredCoreVersion() external pure override returns (uint256) {
        return 1_00; // Requires core v1.0.0+
    }

    /**
     * @dev Calculate and return optimized gas price
     * @return suggestedGasPrice The EMA-based gas price recommendation
     */
    function getOptimizedGasPrice() external nonReentrant returns (uint256 suggestedGasPrice) {
        uint256 currentBaseFee = block.basefee;
        
        // EMA calculation: (current * α) + (previous * (1 - α))
        _emaBaseFee = (
            (currentBaseFee * _alphaNumerator * PRECISION) + 
            (_emaBaseFee * (_alphaDenominator - _alphaNumerator) * PRECISION)
        ) / (_alphaDenominator * PRECISION);
        
        emit EMAUpdated(_emaBaseFee, block.number);
        return _emaBaseFee;
    }

    /**
     * @dev Update EMA calculation parameters (governance only)
     * @param newNumerator New α numerator value
     * @param newDenominator New α denominator value
     */
    function setAlphaParameters(uint256 newNumerator, uint256 newDenominator) external {
        if(msg.sender != _core.governance()) revert UnauthorizedGovernance();
        if(newDenominator <= newNumerator) revert InvalidAlphaParameters();
        
        _alphaNumerator = newNumerator;
        _alphaDenominator = newDenominator;
        emit AlphaParametersUpdated(newNumerator, newDenominator);
    }

    // View functions
    
    /**
     * @dev Get current EMA value
     */
    function currentEMA() external view returns (uint256) {
        return _emaBaseFee;
    }

    /**
     * @dev Get alpha parameters
     */
    function alphaParameters() external view returns (uint256 numerator, uint256 denominator) {
        return (_alphaNumerator, _alphaDenominator);
    }
}