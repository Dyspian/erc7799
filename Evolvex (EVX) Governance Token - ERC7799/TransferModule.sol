contract TransferModule {
    ERC7799Core public core;

    constructor(address _core) {
        core = ERC7799Core(_core);
    }

    function transfer(address to, uint256 amount) external {
        // Example: 2% tax on transfers
        uint256 tax = (amount * 2) / 100;
        uint256 netAmount = amount - tax;

        // Update balances (pseudo-code)
        core.updateBalance(msg.sender, core.balanceOf(msg.sender) - amount);
        core.updateBalance(to, core.balanceOf(to) + netAmount);
        core.updateBalance(taxWallet, core.balanceOf(taxWallet) + tax);
    }
}