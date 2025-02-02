// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ERC7799 Core Contract
 * @dev Core state container with module delegation architecture
 * @author Jimmy Salau
 */
contract ERC7799Core is ReentrancyGuard {
    // Unstructured storage pattern for governance
    bytes32 private constant GOVERNANCE_SLOT = 
        keccak256("erc7799.core.governance");
    
    // Module registry storage
    mapping(bytes4 => address) private _modules;
    
    event ModuleUpdated(
        bytes4 indexed selector,
        address oldModule,
        address newModule
    );
    
    event GovernanceTransferred(
        address previousGovernance,
        address newGovernance
    );

    /**
     * @dev Initialize core with initial governance
     * @param governance Initial governance address
     */
    constructor(address governance) {
        _setGovernance(governance);
    }

    /**
     * @dev Execute module through delegatecall
     */
    fallback(bytes calldata data) 
        external 
        payable 
        nonReentrant 
        returns (bytes memory) 
    {
        bytes4 selector = bytes4(data[:4]);
        address module = _modules[selector];
        
        require(module != address(0), 
            "ERC7799: No module for selector");
        
        (bool success, bytes memory result) = module.delegatecall(data);
        
        if (!success) {
            if (result.length > 0) {
                assembly {
                    revert(add(32, result), mload(result))
                }
            }
            revert("ERC7799: Module call failed");
        }
        
        return result;
    }

    // Governance functions
    
    /**
     * @dev Update module implementation
     * @param selector 4-byte function selector
     * @param module Module address
     */
    function updateModule(bytes4 selector, address module) 
        external 
        onlyGovernance 
    {
        require(module != address(0), 
            "ERC7799: Cannot set null module");
            
        emit ModuleUpdated(
            selector, 
            _modules[selector], 
            module
        );
        
        _modules[selector] = module;
    }

    /**
     * @dev Transfer governance rights
     * @param newGovernance Address of new governance
     */
    function transferGovernance(address newGovernance) 
        external 
        onlyGovernance 
    {
        require(newGovernance != address(0),
            "ERC7799: Invalid governance address");
            
        emit GovernanceTransferred(
            _getGovernance(),
            newGovernance
        );
        
        _setGovernance(newGovernance);
    }

    // Storage management
    
    /**
     * @dev Get current governance address
     */
    function _getGovernance() internal view returns (address gov) {
        bytes32 slot = GOVERNANCE_SLOT;
        assembly {
            gov := sload(slot)
        }
    }

    /**
     * @dev Set governance address in unstructured storage
     * @param newGovernance New governance address
     */
    function _setGovernance(address newGovernance) private {
        bytes32 slot = GOVERNANCE_SLOT;
        assembly {
            sstore(slot, newGovernance)
        }
    }

    // Modifiers
    
    modifier onlyGovernance() {
        require(msg.sender == _getGovernance(),
            "ERC7799: Caller is not governance");
        _;
    }

    // View functions
    
    /**
     * @dev Get module address for function selector
     * @param selector 4-byte function selector
     */
    function getModule(bytes4 selector) 
        external 
        view 
        returns (address) 
    {
        return _modules[selector];
    }

    /**
     * @dev Get current governance address
     */
    function governance() external view returns (address) {
        return _getGovernance();
    }
}
