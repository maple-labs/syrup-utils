// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IGlobalsLike } from "./interfaces/Interfaces.sol";
import { ISyrupDrip }   from "./interfaces/ISyrupDrip.sol";

contract SyrupDrip is ISyrupDrip {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    address public asset;
    address public globals;

    bytes32 public override root;

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

    // TODO: Consider adding a `minId` when creating a new allocation, this would prevent id's from old allocations ever being reused.
    function allocate(bytes32 root_, uint256 deadline_) external override onlyProtocolAdmins {
        require(deadline_ >= block.timestamp, "SD:A:INVALID_DEADLINE");

        root     = root_;
        deadline = deadline_;

        emit Allocated(root_, deadline_);
    }

}
