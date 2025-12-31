TORK Staking Contract

This repository contains the source code for the TORK staking smart contract, designed to distribute staking rewards in a transparent, time-based, and permissionless manner.

The contract is written in Solidity and targets Binance Smart Chain (BSC) compatible networks.

Overview

The TORK staking contract allows users to stake TORK tokens and earn rewards over time based on:

The amount of tokens staked

The duration of staking

A fixed reward emission rate

Rewards are distributed per second and are shared proportionally among all active stakers.

Key Characteristics

Permissionless staking

No owner privileges

No withdrawal or emergency admin functions

Immutable reward logic

Fully on-chain reward accounting

Once deployed, the contract operates autonomously according to its code.

Reward Model

Reward Rate: 1 token per second

Daily Emission: 86,400 tokens

Distribution Method: Proportional to stake share

Reward Source: Tokens pre-funded into the contract

If the contract runs out of reward tokens, reward distribution automatically stops.

How It Works
Pool Accounting

The contract uses an accRewardPerShare model to track rewards efficiently:

Rewards accumulate over time

Each user’s pending reward is calculated based on their share of the total staked amount

Rewards are updated whenever users interact with the contract

Functions
stake(uint256 amount)

Stakes the specified amount of tokens

Automatically claims pending rewards before updating the stake

unstake(uint256 amount)

Withdraws staked tokens

Claims any pending rewards at the same time

claim()

Claims accumulated rewards without unstaking tokens

pendingReward(address user)

View function to check unclaimed rewards

Security Design

No owner or admin functions

No ability to withdraw or reclaim user funds

No minting or reward manipulation

Reward calculation protected against overflow

Safe arithmetic under Solidity ^0.8.x

Tokens sent into the contract cannot be withdrawn by the deployer and are used exclusively for reward distribution.

Token Requirements

The staking contract expects the token to be:

BEP-20 / ERC-20 compatible

Using 18 decimals

Supporting transfer and transferFrom

Deployment

The token address must be provided during deployment:

constructor(address _token)


Once deployed, the token address is immutable.

Transparency

Fully open-source

Verifiable on-chain

Community auditable

Deterministic behavior

Users are encouraged to review the code before interacting.

Disclaimer

This smart contract is provided as-is, without warranties of any kind.

The contract does not represent a financial product or investment instrument.
Users interact with the contract at their own risk and responsibility.

License

MIT License
