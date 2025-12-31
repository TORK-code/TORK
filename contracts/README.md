Minimal Staking Contract for BEP-20 Tokens

This repository contains a minimal, permissionless, and transparent staking smart contract written in Solidity.

The contract enables users to stake BEP-20 compatible tokens and earn rewards over time based on a fixed, time-based emission model. It is intentionally designed to remain simple, predictable, and fully auditable.

📌 Features

Permissionless staking

Time-based reward distribution

Fixed reward emission rate

Proportional reward sharing

No owner or admin privileges

No withdrawal or emergency controls

Fully on-chain reward accounting

Simple and readable codebase

📜 Contract Overview

The staking contract allows users to:

Stake tokens into the contract

Earn rewards distributed per second

Claim rewards at any time

Unstake partially or fully

Rewards are distributed proportionally based on each user’s share of the total staked amount.

The contract does not include:

Owner or admin intervention

Emergency withdrawal functions

Reward manipulation mechanisms

Upgradeability or proxy patterns

Hidden or privileged logic

⏱ Reward Model

Reward Rate: 1 token per second

Daily Distribution: 86,400 tokens

Reward Source: Tokens pre-funded into the contract

Distribution Method: Proportional to stake share

If the reward token balance inside the contract is depleted, reward distribution automatically stops.

⚙️ How It Works

The contract uses an accumulator-based accounting model (accRewardPerShare) to track rewards efficiently.

Rewards accumulate continuously over time

Pool state updates only when users interact

Each user’s rewards are calculated based on:

Amount staked

Time staked

Total pool size

This approach ensures fair and gas-efficient reward distribution.

🧾 Main Functions
stake(uint256 amount)

Stakes the specified amount of tokens into the pool.
Automatically claims any pending rewards before updating the stake.

unstake(uint256 amount)

Withdraws a specified amount of staked tokens.
Pending rewards are claimed during the process.

claim()

Claims accumulated rewards without unstaking tokens.

pendingReward(address user)

View function that returns the user’s unclaimed rewards.

🔐 Security Design

No owner or admin role

No ability to withdraw user funds

No reward rate modification

No minting or external token creation

Solidity ^0.8.x overflow protection

Tokens deposited into the contract cannot be reclaimed by the deployer and are used exclusively for reward distribution.

🔗 Token Requirements

The staking contract expects the token to be:

BEP-20 / ERC-20 compatible

Using 18 decimals

Supporting transfer and transferFrom

🛠 Deployment

The token address is provided at deployment time:

constructor(address _token)


Once deployed, the token address is immutable.

🔍 Transparency

Fully open-source

Verifiable on-chain

Community auditable

Deterministic and predictable behavior

Users are encouraged to review the source code before interacting with the contract.

📄 License

This project is licensed under the MIT License.
