contract GovernanceModule {
    ERC7799Core public core;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    struct Proposal {
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    constructor(address _core) {
        core = ERC7799Core(_core);
    }

    function createProposal(string memory description) external {
        proposals[proposalCount++] = Proposal({
            proposer: msg.sender,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        uint256 votingPower = core.balanceOf(msg.sender);
        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
    }
}