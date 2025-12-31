// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TORKStaking {

    IERC20 public immutable token;

    uint256 public rewardRate = 1 ether;
    uint256 public lastUpdateTime;
    uint256 public accRewardPerShare;
    uint256 public totalStaked;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => UserInfo) public users;

    constructor(address _token) {
        token = IERC20(_token);
        lastUpdateTime = block.timestamp;
    }

    function _updatePool() internal {
        if (totalStaked == 0) {
            lastUpdateTime = block.timestamp;
            return;
        }

        uint256 rewardBalance = token.balanceOf(address(this));
        if (rewardBalance == 0) return;

        uint256 timePassed = block.timestamp - lastUpdateTime;
        uint256 reward = timePassed * rewardRate;

        if (reward > rewardBalance) {
            reward = rewardBalance;
        }

        accRewardPerShare += (reward * 1e12) / totalStaked;
        lastUpdateTime = block.timestamp;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount zero");

        _updatePool();

        UserInfo storage user = users[msg.sender];

        if (user.amount > 0) {
            uint256 pending =
                (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;

            if (pending > 0) {
                token.transfer(msg.sender, pending);
            }
        }

        token.transferFrom(msg.sender, address(this), amount);

        user.amount += amount;
        totalStaked += amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
    }

    function unstake(uint256 amount) external {
        UserInfo storage user = users[msg.sender];
        require(user.amount >= amount, "Not enough stake");

        _updatePool();

        uint256 pending =
            (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;

        if (pending > 0) {
            token.transfer(msg.sender, pending);
        }

        user.amount -= amount;
        totalStaked -= amount;

        token.transfer(msg.sender, amount);

        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
    }

    function claim() external {
        _updatePool();

        UserInfo storage user = users[msg.sender];

        uint256 pending =
            (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;

        require(pending > 0, "No reward");

        token.transfer(msg.sender, pending);
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = users[_user];
        uint256 _acc = accRewardPerShare;

        if (totalStaked > 0) {
            uint256 rewardBalance = token.balanceOf(address(this));
            uint256 timePassed = block.timestamp - lastUpdateTime;
            uint256 reward = timePassed * rewardRate;

            if (reward > rewardBalance) {
                reward = rewardBalance;
            }

            _acc += (reward * 1e12) / totalStaked;
        }

        return (user.amount * _acc) / 1e12 - user.rewardDebt;
    }
}
