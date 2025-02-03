// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC7799Module.sol";
import "../ERC7799Core.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title VersionControlModule
 * @dev Semantic versioning and compatibility management system
 * @author Jimmy Salau
 * @notice Manages version dependencies and upgrade compatibility
 */
contract VersionControlModule is IERC7799Module {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    ERC7799Core private immutable _core;
    
    struct Version {
        uint32 major;
        uint32 minor;
        uint32 patch;
        uint32 requiredCoreVersion;
    }
    
    struct Compatibility {
        bool backwardCompatible;
        bytes32 checksum;
    }

    // Storage
    mapping(address => Version) private _moduleVersions;
    mapping(bytes32 => Compatibility) private _compatibility;
    Version private _coreVersion;
    EnumerableSet.AddressSet private _registeredModules;

    // Events
    event VersionUpdated(
        address indexed module,
        uint32 major,
        uint32 minor,
        uint32 patch,
        uint32 requiredCore
    );
    
    event CompatibilitySet(
        bytes32 versionHash,
        bool backwardCompatible,
        bytes32 checksum
    );

    // Errors
    error UnauthorizedAccess();
    error InvalidVersion();
    error IncompatibleVersion();
    error ModuleNotRegistered();

    constructor(address coreAddress, uint32 initialMajor, uint32 initialMinor) {
        _core = ERC7799Core(coreAddress);
        _coreVersion = Version(initialMajor, initialMinor, 0, 0);
    }

    // Module interface implementation
    function moduleName() external pure override returns (string memory) {
        return "VersionControlModule";
    }

    function moduleVersion() external pure override returns (uint256) {
        return 1_00; // 1.0.0
    }

    function requiredCoreVersion() external pure override returns (uint256) {
        return 1_00; // Requires core v1.0.0+
    }

    /**
     * @dev Register/modify module version (Governance only)
     */
    function setModuleVersion(
        address module,
        uint32 major,
        uint32 minor,
        uint32 patch,
        uint32 requiredCore
    ) external onlyGovernance {
        Version memory newVersion = Version(major, minor, patch, requiredCore);
        
        if(requiredCore > _coreVersion.major << 16 | _coreVersion.minor) {
            revert IncompatibleVersion();
        }
        
        _moduleVersions[module] = newVersion;
        _registeredModules.add(module);
        
        emit VersionUpdated(module, major, minor, patch, requiredCore);
    }

    /**
     * @dev Set version compatibility (Governance only)
     */
    function setCompatibility(
        uint32 fromMajor,
        uint32 fromMinor,
        uint32 toMajor,
        uint32 toMinor,
        bool compatible,
        bytes32 checksum
    ) external onlyGovernance {
        bytes32 key = keccak256(abi.encodePacked(fromMajor, fromMinor, toMajor, toMinor));
        _compatibility[key] = Compatibility(compatible, checksum);
        emit CompatibilitySet(key, compatible, checksum);
    }

    /**
     * @dev Check module compatibility
     */
    function isCompatible(
        address module,
        uint32 coreMajor,
        uint32 coreMinor
    ) external view returns (bool) {
        if(!_registeredModules.contains(module)) revert ModuleNotRegistered();
        
        Version memory req = _moduleVersions[module];
        bytes32 key = keccak256(abi.encodePacked(
            req.requiredCoreVersion >> 16,
            req.requiredCoreVersion & 0xFFFF,
            coreMajor,
            coreMinor
        ));
        
        return _compatibility[key].backwardCompatible;
    }

    /**
     * @dev Get current core version
     */
    function getCoreVersion() external view returns (uint32 major, uint32 minor, uint32 patch) {
        return (_coreVersion.major, _coreVersion.minor, _coreVersion.patch);
    }

    /**
     * @dev Upgrade core version (Governance only)
     */
    function upgradeCoreVersion(
        uint32 major,
        uint32 minor,
        uint32 patch
    ) external onlyGovernance {
        if(major <= _coreVersion.major && minor <= _coreVersion.minor) {
            revert InvalidVersion();
        }
        
        _coreVersion = Version(major, minor, patch, 0);
    }

    modifier onlyGovernance() {
        if(msg.sender != _core.governance()) revert UnauthorizedAccess();
        _;
    }
}
