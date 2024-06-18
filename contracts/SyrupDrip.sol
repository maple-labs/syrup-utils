// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IGlobalsLike } from "./interfaces/Interfaces.sol";
import { ISyrupDrip }   from "./interfaces/ISyrupDrip.sol";

// TODO: Should this contract be an NTP?
// TODO: Should monitor for failing claims in case of insufficient assets in the contract.
contract SyrupDrip is ISyrupDrip {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    address public override asset;
    address public override globals;

    bytes32 public override root;

    // TODO: Should this be a `uint32` since it is timestamp?
    uint256 public override deadline;

    /**************************************************************************************************************************************/
    /*** Constructor                                                                                                                    ***/
    /**************************************************************************************************************************************/

    constructor(address asset_, address globals_) {
        asset   = asset_;
        globals = globals_;
    }

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier onlyProtocolAdmins {
        address globals_ = globals;

        require(
            msg.sender == IGlobalsLike(globals_).governor() ||
            msg.sender == IGlobalsLike(globals_).operationalAdmin(),
            "SD:NOT_AUTHORIZED"
        );

        _;
    }

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    // TODO: Should we even set the deadline? Or just wait until a new allocation is added to cancel the existing one.
    // TODO: Should this also perform an automatic reclaim? Should it pull tokens from somewhere or anything like that?
    // TODO: Should we check if the deadline has already expired?
    // TODO: Is setting a root of zero or having no allocations expected?
    function allocate(bytes32 root_, uint256 deadline_) external override onlyProtocolAdmins {
        require(deadline_ >= block.timestamp, "SD:A:EXPIRED");

        root     = root_;
        deadline = deadline_;

        emit Allocated(root_, deadline_);
    }

}
