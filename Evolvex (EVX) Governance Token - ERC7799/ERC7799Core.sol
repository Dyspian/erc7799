// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC7799Core.sol";

contract EvolveX is ERC7799Core {
    constructor(address _governance) ERC7799Core(_governance) {
        // Initialize default modules
        modules[0xa9059cbb] = address(new TransferModule()); // Transfer logic
        modules[0x23b872dd] = address(new TransferFromModule()); // TransferFrom logic
    }
}