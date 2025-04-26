// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract RestakingContract {
    IERC20 public stakingToken;

    uint256 public rewardRate = 100; // Example: 100 tokens per second, adjust based on your logic
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) public balances;
    uint256 private _totalSupply;

    constructor(address _tokenAddress) {
        stakingToken = IERC20(_tokenAddress);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        balances[msg.sender] += amount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    function restakeRewards() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to restake");

        rewards[msg.sender] = 0;
        _totalSupply += reward;
        balances[msg.sender] += reward;
        // No transfer because rewards are already held by the contract
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        _totalSupply -= amount;
        balances[msg.sender] -= amount;
        stakingToken.transfer(msg.sender, amount);
    }

    function claimRewards() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");
        rewards[msg.sender] = 0;
        stakingToken.transfer(msg.sender, reward);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}
