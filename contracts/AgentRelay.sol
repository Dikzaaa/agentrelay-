// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IAgentId {
    function balanceOf(address owner) external view returns (uint256);
}

/// @notice A public, non-custodial coordination board for Agent ID holders.
/// @dev Mainnet Agent ID contract: 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F.
///      No administrator, fees, upgrades, asset transfers or token approvals.
contract AgentRelay {
    IAgentId public immutable agentId;
    enum Status { Open, Claimed, Completed, Cancelled }
    struct Task { address creator; address claimant; Status status; string brief; }
    Task[] private tasks;

    event TaskCreated(uint256 indexed id, address indexed creator, string brief);
    event TaskClaimed(uint256 indexed id, address indexed claimant);
    event TaskReleased(uint256 indexed id, address indexed claimant);
    event TaskCompleted(uint256 indexed id, address indexed creator, address indexed claimant);
    event TaskCancelled(uint256 indexed id, address indexed creator);

    error InvalidAgentIdContract();
    error AgentIdRequired();
    error InvalidBrief();
    error InvalidTask();
    error InvalidState();
    error NotAuthorized();

    constructor(address idContract) {
        if (idContract.code.length == 0) revert InvalidAgentIdContract();
        agentId = IAgentId(idContract);
    }
    modifier onlyAgent() {
        if (agentId.balanceOf(msg.sender) == 0) revert AgentIdRequired();
        _;
    }
    function taskCount() external view returns (uint256) { return tasks.length; }
    function getTask(uint256 id) external view returns (address creator, address claimant, Status status, string memory brief) {
        if (id >= tasks.length) revert InvalidTask();
        Task storage t = tasks[id];
        return (t.creator, t.claimant, t.status, t.brief);
    }
    function createTask(string calldata brief) external onlyAgent returns (uint256 id) {
        uint256 size = bytes(brief).length;
        if (size == 0 || size > 160) revert InvalidBrief();
        id = tasks.length;
        tasks.push(Task(msg.sender, address(0), Status.Open, brief));
        emit TaskCreated(id, msg.sender, brief);
    }
    function claimTask(uint256 id) external onlyAgent {
        if (id >= tasks.length) revert InvalidTask();
        Task storage t = tasks[id];
        if (t.status != Status.Open) revert InvalidState();
        if (t.creator == msg.sender) revert NotAuthorized();
       
