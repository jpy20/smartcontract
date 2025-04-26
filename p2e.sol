// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract PlayToEarn {
    IERC20 public rewardToken;
    address public owner;
    uint256 public rewardAmount;
    
    mapping(address => uint256) public missionsCompleted;

    event MissionCompleted(address indexed player, uint256 missionId, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _tokenAddress, uint256 _rewardAmount) {
        rewardToken = IERC20(_tokenAddress);
        owner = msg.sender;
        rewardAmount = _rewardAmount;
    }

    function setRewardAmount(uint256 _newRewardAmount) external onlyOwner {
        rewardAmount = _newRewardAmount;
    }

    function rewardPlayer(address _player, uint256 _missionId) external onlyOwner {
        require(_player != address(0), "Invalid player address");
        require(missionsCompleted[_player] < _missionId, "Already rewarded for this mission");

        missionsCompleted[_player] = _missionId;
        rewardToken.transfer(_player, rewardAmount);

        emit MissionCompleted(_player, _missionId, rewardAmount);
    }

    function withdrawTokens(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address");
        rewardToken.transfer(_to, _amount);
    }
}
