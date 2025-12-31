# Minimal BEP-20 Token with Burn Function

This repository contains a minimal and transparent implementation of a BEP-20 compatible token smart contract written in Solidity.

The contract is designed to be simple, auditable, and easy to understand, without complex mechanics or hidden logic.

---

## 📌 Features

- BEP-20 compatible
- Fixed total supply
- No mint function
- Burn functionality
- Allowance & approval system
- Ownership renouncement support
- Simple and readable codebase

---

## 📜 Contract Overview

The smart contract includes the following core components:

- Token transfers
- Allowance-based transfers (`approve` / `transferFrom`)
- Token burning (reduces total supply)
- Ownership control with renouncement option

The contract does **not** include:
- Transaction fees
- Reflections
- Rebasing
- Pausing or blacklisting
- Hidden privileged functions

---

## 🔥 Burn Mechanism

Token holders can permanently reduce the circulating supply by calling the `burn` function.

- Burned tokens are sent to the zero address
- Total supply is reduced accordingly
- All burn events are recorded on-chain

---

## 🔐 Ownership

- The contract is deployed with an initial owner
- The owner can renounce ownership permanently
- After renouncement, no owner-only functions remain
- The contract becomes fully decentralized

---

## 🧾 Main Functions

### `transfer(address to, uint256 value)`
Transfers tokens from the caller to another address.

### `approve(address spender, uint256 value)`
Approves a spender to use a specified amount of tokens.

### `transferFrom(address from, address to, uint256 value)`
Transfers tokens on behalf of another address using allowance.

### `burn(uint256 value)`
Permanently removes tokens from circulation.

### `renounceOwnership()`
Removes ownership privileges permanently.

---

## 🔍 Security Notes

- Solidity version `^0.8.x` (built-in overflow protection)
- No minting capability
- No upgradeability
- No external dependencies
- Logic kept intentionally minimal for auditability

---

## 🛠 Usage

This contract can be used as:
- A learning reference
- A base for simple token projects
- A starting point for further customization

Before deploying to mainnet, thorough testing and review are strongly recommended.

---

## ⚠️ Disclaimer

This repository is provided for educational and informational purposes only.  
It does not constitute financial advice.  
Use at your own risk.

---

## 📄 License

This project is licensed under the MIT License.





# Minimal BEP-20 Staking Contract

This repository contains a minimal and transparent staking smart contract
designed for BEP-20 compatible tokens, written in Solidity.

The contract is intentionally designed to be simple, auditable, and predictable,
without complex mechanics or privileged control.

---

## 📌 Features

- Permissionless staking
- Time-based reward distribution
- Fixed reward emission rate
- Proportional reward sharing
- No owner or admin privileges
- No emergency withdrawal functions
- Simple and readable codebase

---

## 📜 Contract Overview

The staking contract allows users to:

- Stake supported tokens
- Earn rewards over time
- Claim rewards independently
- Unstake partially or fully

Rewards are distributed proportionally based on each user’s share
of the total staked amount.

The contract does **not** include:

- Owner or admin intervention
- Reward manipulation logic
- Emergency fund access
- Upgradeability or proxy patterns
- Hidden privileged functions

---

## ⏱ Reward Mechanism

Rewards are distributed continuously based on time and staking participation.

- Reward Rate: `1 token per second`
- Daily Distribution: `86,400 tokens`
- Distribution Method: Proportional to stake share
- Reward Source: Tokens pre-funded into the contract

If the contract’s reward balance is depleted,
reward distribution automatically stops.

---

## 🧾 Main Functions

### `stake(uint256 amount)`

Stakes the specified amount of tokens into the contract.
Automatically claims any pending rewards before updating the stake.

### `unstake(uint256 amount)`

Withdraws the specified amount of staked tokens.
Pending rewards are claimed during the process.

### `claim()`

Claims accumulated rewards without unstaking tokens.

### `pendingReward(address user)`

Returns the amount of unclaimed rewards for a given address.

---

## 🔐 Security Design

- No owner or admin role
- No ability to withdraw user funds
- No reward rate modification
- No minting or external token creation
- Solidity `^0.8.x` built-in overflow protection

Tokens deposited into the contract cannot be reclaimed by the deployer
and are used exclusively for reward distribution.

---

## 🔗 Token Requirements

The staking contract expects the token to be:

- BEP-20 / ERC-20 compatible
- Using 18 decimals
- Supporting `transfer` and `transferFrom`

---

## 🛠 Deployment

The token address must be provided during deployment:

```solidity
constructor(address _token)
