# BitLeverage

## Decentralized Margin Trading Protocol on Stacks

**BitLeverage** is a trust-minimized, secure, and transparent margin trading protocol built on **Stacks Layer 2**, leveraging Bitcoin's final settlement assurances. It enables users to open leveraged long and short positions on STX with configurable leverage up to **20x**, using STX as collateral.

## Overview

BitLeverage allows traders to gain directional exposure to price movements without fully owning the underlying asset. The protocol is engineered with safety, compliance, and composability in mind, offering:

* Long and short trading positions
* Transparent liquidation mechanics
* Bitcoin-settled security via Stacks
* Configurable leverage (1x–20x)
* Strict collateral management
* Oracle-based price feed (upgradable)

## Features

### ✔️ Leverage Trading

Users can open **long or short positions** with configurable leverage. The protocol calculates collateral requirements and liquidation thresholds on-chain.

### ✔️ Automated Liquidation

If market price crosses a position’s liquidation price, the position is eligible to be liquidated, protecting the protocol from under-collateralization.

### ✔️ Collateralized by STX

Users deposit STX to open positions. Positions are fully backed with a minimum collateral ratio of **150%**.

### ✔️ Permissioned Oracle

The protocol includes a `update-price` admin function, simulating a price oracle for test and early deployment phases.

### ✔️ Admin Controls

* Pause/resume contract operations
* Transfer contract ownership
* Update market price manually (stub for oracle)

## Smart Contract Summary

| Component             | Description                                                       |
| --------------------- | ----------------------------------------------------------------- |
| **Balances Map**      | Tracks deposited STX for each user                                |
| **Positions Map**     | Stores all open positions with leverage, size, entry price, etc.  |
| **Position Types**    | Long (`u1`) and Short (`u2`)                                      |
| **Collateral Ratio**  | Minimum ratio set to `150%` (`MIN-COLLATERAL-RATIO`)              |
| **Leverage Limits**   | Maximum allowed leverage is `20x` (`MAX-LEVERAGE`)                |
| **Liquidation Logic** | Auto-check for liquidation eligibility using current market price |

## Key Functions

### Public Functions

| Function              | Purpose                                                                   |
| --------------------- | ------------------------------------------------------------------------- |
| `deposit-collateral`  | Add STX to your margin account                                            |
| `withdraw-collateral` | Withdraw unused STX from margin account                                   |
| `open-position`       | Open a long/short position with specified size and leverage               |
| `close-position`      | Close a position and realize PnL or trigger liquidation if eligible       |
| `liquidate-position`  | Liquidate undercollateralized positions and receive 5% liquidation bounty |

### Read-Only Functions

| Function                      | Purpose                                                       |
| ----------------------------- | ------------------------------------------------------------- |
| `get-balance`                 | Retrieve your deposited STX balance                           |
| `get-position`                | View position details by ID                                   |
| `get-current-price`           | Get current oracle market price                               |
| `is-liquidatable`             | Check if a position is eligible for liquidation               |
| `calculate-liquidation-price` | Calculate liquidation threshold for given position parameters |

### Admin Functions

| Function              | Purpose                                   |
| --------------------- | ----------------------------------------- |
| `update-price`        | Manually update price oracle (owner only) |
| `set-contract-owner`  | Transfer ownership of contract            |
| `set-contract-paused` | Pause/unpause trading activity            |

## Liquidation Pricing Logic

Liquidation price depends on **entry price** and **leverage**:

* **Long:** `entry * (1 - 1/leverage)`
* **Short:** `entry * (1 + 1/leverage)`

Example:

* Entry price: 100
* Leverage: 5x
* Long liquidation price: `100 * (1 - 1/5)` = `80`

## Example Usage

```clarity
;; Deposit 1000 STX as collateral
(deposit-collateral u100000000000)

;; Open a 5x long position with size 500
(open-position u1 u500 u5)

;; Update price to simulate market movement
(update-price u120)

;; Close the position
(close-position u1)
```

## Risks & Warnings

* This is an early-stage protocol—**auditing and formal verification are essential** before mainnet deployment.
* Oracle pricing is currently **manually updated**; production deployments must integrate a secure and decentralized price oracle.
* Improper handling of paused states or admin keys could result in stuck funds or protocol misuse.

## Built With

* **Clarity**: Smart contract language on Stacks
* **Stacks Blockchain**: Bitcoin-secured Layer 2
* **STX Token**: Used as collateral and settlement currency

## Security Roadmap

* ✅ Error codes for safe failure handling
* ✅ Pausable contract operations
* 🔲 Oracle integration (e.g., Chainlink, Hiro Pyth)
* 🔲 Independent audits
* 🔲 Bug bounty program
