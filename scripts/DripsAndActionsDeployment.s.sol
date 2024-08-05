// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { console2 as console, Script } from "../modules/forge-std/src/Script.sol";

import { MplUserActions }   from "../contracts/MplUserActions.sol";
import { SyrupDrip }        from "../contracts/SyrupDrip.sol";
import { SyrupUserActions } from "../contracts/SyrupUserActions.sol";

contract DeploySyrupDripsAndActions is Script {

    function run() external {
        address deployer = vm.envAddress("ETH_SENDER");

        address dai       = vm.envAddress("DAI");
        address globals   = vm.envAddress("GLOBALS");
        address migrator  = vm.envAddress("MIGRATOR");
        address psm       = vm.envAddress("PSM");
        address sDai      = vm.envAddress("SDAI");
        address syrup     = vm.envAddress("SYRUP"); 
        address syrupUsdc = vm.envAddress("SYRUP_USDC");
        address stSyrup   = vm.envAddress("STAKED_SYRUP");
        address xmpl      = vm.envAddress("XMPL");

        bytes32 poolId = vm.envBytes32("POOL_ID");

        vm.startBroadcast(deployer);

        address drips = address(new SyrupDrip(syrup, globals, stSyrup));
        console.log("SyrupDrips deployed at: %s", drips);

        address mplUserActions = address(new MplUserActions(migrator, xmpl, stSyrup));
        console.log("MplUserActions deployed at: %s", mplUserActions);

        // address dai_, address psm_, address sDai_, address syrupUsdc_, bytes32 poolId_
        address syrupUserActions = address(new SyrupUserActions(dai, psm, sDai, syrupUsdc, poolId));
        console.log("SyrupUserActions deployed at: %s", syrupUserActions);

        vm.stopBroadcast();
    }

}
