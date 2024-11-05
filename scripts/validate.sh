#!/usr/bin/env bash

source .env

export FOUNDRY_PROFILE=production
echo Using profile: $FOUNDRY_PROFILE

# Validates an allocation file
forge script \
    --rpc-url $ETH_RPC_URL \
    --unlocked \
    --slow \
    scripts/ValidateAllocation.s.sol:ValidateAllocation
