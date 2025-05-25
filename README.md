# Syrup Utils

![CI](https://github.com/maple-labs/syrup-utils/actions/workflows/ci.yml/badge.svg)
[![GitBook - Documentation](https://img.shields.io/badge/GitBook-Documentation-orange?logo=gitbook&logoColor=white)](https://syrup.gitbook.io/syrup)
[![Foundry][foundry-badge]][foundry]
[![License: BUSL 1.1](https://img.shields.io/badge/License-BUSL%201.1-blue.svg)](https://github.com/maple-labs/syrup-utils/blob/main/LICENSE)

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

## Overview

This repository contains utility contracts that are used as part of Maple's permissionless offering Syrup. This include:
| Path                         | Description |
|------------------------------|--------------------|
| `contracts/SyrupDrip.sol` | Merkle Tree based airdrop distributor |
| `contracts/SyrupUserActions.sol` | Convenience contract for users to swap directly to USDC / DAI |
| `contracts/MplUserActions.sol` | Convenience contract for users to migrate to Syrup / stSyrup |
| `contracts/SyrupRouter.sol` | Router that allows deposits into a Maple Pool |
| `contracts/utils/SyrupRateProvider.sol` | Price Oracle for Balancer pools |
## Submodules

Submodules imported:
* modules/erc20
* modules/erc20-helper
* modules/forge-std
* modules/globals-v2
* modules/lite-psm
* modules/maple-token
* modules/mpl-migration
* modules/mpl-v2
* modules/open-zeppelin
* modules/xmpl

Versions of dependencies can be checked with `git submodule status`.

## Setup

This project was built using [Foundry](https://book.getfoundry.sh/). Refer to installation instructions [here](https://github.com/foundry-rs/foundry#installation).

```sh
git clone git@github.com:maple-labs/syrup-utils.git
cd syrup-utils
forge install
```

## Audit Reports

| Auditor | Report link |
|---|---|
| ThreeSigma | [ThreeSigma-MapleSyrupRouter.pdf](https://github.com/maple-labs/syrup-utils-private/blob/main/audits/ThreeSigma-MapleSyrupRouter.pdf) |
| ThreeSigma | [ThreeSigma-Maple-Finance-Aug-2024.pdf](https://github.com/maple-labs/syrup-utils-private/blob/main/audits/ThreeSigma-Maple-Finance-Aug-2024.pdf) |
| 0xMacro | [0xMacro-Maple-Finance-Aug-2024.pdf](https://github.com/maple-labs/syrup-utils-private/blob/main/audits/0xMacro-Maple-Finance-Aug-2024.pdf) |


## Bug Bounty

For all information related to the ongoing bug bounty for these contracts run by [Immunefi](https://immunefi.com/), please visit this [site](https://immunefi.com/bounty/maple/).

## About Maple

[Maple Finance](https://maple.finance/) is a decentralized corporate credit market. Maple provides capital to institutional borrowers through globally accessible fixed-income yield opportunities.

---

<p align="center">
  <img src="https://github.com/maple-labs/maple-metadata/blob/796e313f3b2fd4960929910cd09a9716688a4410/assets/maplelogo.png" height="100" />
</p>
