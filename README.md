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
