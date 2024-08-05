#!/usr/bin/env bash
. .env

# NOTE to add --broadcast flag when sending
# To use a different wallet index, add --mnemonic-indexes n where n is the index
export FOUNDRY_PROFILE=production
echo Using profile: $FOUNDRY_PROFILE

# For Testing
forge script \
    --rpc-url $ETH_RPC_URL \
    -vvvv \
    --unlocked \
    --slow \
    --sender "$ETH_SENDER" \
    scripts/DripsAndActionsDeployment.s.sol:DeploySyrupDripsAndActions


# For Drips and Actions deployment
# forge script \
#     --rpc-url $ETH_RPC_URL \
#     -vvvv \
#     --mnemonic-indexes 2 \
#     --ledger \
#     --slow \
#     --sender $ETH_SENDER \
#     --gas-estimate-multiplier 150 \
#     --broadcast \
#     scripts/DripsAndActionsDeployment.s.sol:DeploySyrupDripsAndActions
