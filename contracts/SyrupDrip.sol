// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";
import { MerkleProof } from "../modules/open-zeppelin/contracts/utils/cryptography/MerkleProof.sol";

import { IGlobalsLike } from "./interfaces/Interfaces.sol";
import { ISyrupDrip }   from "./interfaces/ISyrupDrip.sol";

contract SyrupDrip is ISyrupDrip {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    address public override asset;
    address public override globals;

    bytes32 public override root;

    uint256 public override deadline;

    mapping(uint256 => uint256) public override bitmaps;

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
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // TODO: Consider adding a `minId` when creating a new allocation, this would prevent id's from old allocations ever being reused.
    function allocate(bytes32 root_, uint256 deadline_) external override onlyProtocolAdmins {
        require(deadline_ >= block.timestamp, "SD:A:INVALID_DEADLINE");

        root     = root_;
        deadline = deadline_;

        emit Allocated(root_, deadline_);
    }

    function claim(uint256 id_, address account_, uint256 amount_, bytes32[] calldata proof_) external override {
        require(!_isClaimed(id_),            "SD:C:ALREADY_CLAIMED");
        require(block.timestamp <= deadline, "SD:C:EXPIRED_DEADLINE");

        bytes32 leaf_ = keccak256(bytes.concat(keccak256(abi.encode(id_, account_, amount_))));

        require(MerkleProof.verify(proof_, root, leaf_), "SD:C:INVALID_PROOF");

        _setClaimed(id_);

        require(ERC20Helper.transfer(asset, account_, amount_), "SD:C:TRANSFER_FAIL");

        emit Claimed(id_, account_, amount_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // TODO: Consider where comments for internal functions should go
    // Checks if a token allocation has already been claimed.
    function _isClaimed(uint256 id_) internal view returns (bool isClaimed_) {
        uint256 key_  = id_ / 256;
        uint256 flag_ = id_ % 256;
        uint256 word_ = bitmaps[key_];
        uint256 mask_ = (1 << flag_);

        isClaimed_ = word_ & mask_ == mask_;
    }

    // Registers a token allocation as claimed.
    function _setClaimed(uint256 id_) internal {
        uint256 key_  = id_ / 256;
        uint256 flag_ = id_ % 256;

        bitmaps[key_] = bitmaps[key_] | (1 << flag_);
    }

}
