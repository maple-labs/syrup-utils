// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { ISyrupRouter } from "./interfaces/ISyrupRouter.sol";

import {
    IERC20Like,
    IPoolLike,
    IPoolManagerLike,
    IPoolPermissionManagerLike
} from "./interfaces/Interfaces.sol";

contract SyrupRouter is ISyrupRouter {

    address public immutable override asset;
    address public immutable override pool;
    address public immutable override poolManager;
    address public immutable override poolPermissionManager;

    constructor(address pool_) {
        pool = pool_;

        // Get the addresses of all the associated contracts.
        address asset_ = asset = IPoolLike(pool_).asset();
        address poolManager_ = poolManager = IPoolLike(pool_).manager();

        poolPermissionManager = IPoolManagerLike(poolManager_).poolPermissionManager();

        // Perform an infinite approval.
        require(ERC20Helper.approve(asset_, pool_, type(uint256).max), "SR:C:APPROVE_FAIL");
    }

    function deposit(uint256 amount_, bytes32 depositData_) external override returns (uint256 shares_) {
        shares_ = _deposit(msg.sender, amount_, depositData_);
    }

    function depositWithPermit(
        uint256 amount_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_,
        bytes32 depositData_
    ) external override returns (uint256 shares_) {
        address asset_ = asset;
        uint256 allowance_ = IERC20Like(asset_).allowance(msg.sender, address(this));

        if (allowance_ < amount_) {
            IERC20Like(asset_).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);
        }

        shares_ = _deposit(msg.sender, amount_, depositData_);
    }

    function _deposit(address owner_, uint256 amount_, bytes32 depositData_) internal returns (uint256 shares_) {
        // Check the owner has permission to deposit into the pool.
        require(
            IPoolPermissionManagerLike(poolPermissionManager).hasPermission(poolManager, owner_, "P:deposit"),
            "SR:D:NOT_AUTHORIZED"
        );

        // Pull assets from the owner to the router.
        require(ERC20Helper.transferFrom(asset, owner_, address(this), amount_), "SR:D:TRANSFER_FROM_FAIL");

        // Deposit assets into the pool and receive the shares personally.
        address pool_ = pool;

        shares_ = IPoolLike(pool_).deposit(amount_, address(this));

        // Route shares back to the caller.
        require(ERC20Helper.transfer(pool_, owner_, shares_), "SR:D:TRANSFER_FAIL");

        emit DepositData(owner_, amount_, depositData_);
    }

}
