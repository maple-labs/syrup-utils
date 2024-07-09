// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test } from "../../modules/forge-std/src/Test.sol";

import { MplUserActions } from "../../contracts/MplUserActions.sol";

// TODO
contract MplUserActionsIntegrationTestBase is Test {

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20184000);
    }

}
