// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { IMplUserActions }         from "./interfaces/IMplUserActions.sol";
import { IMigratorLike, IRDTLike } from "./interfaces/Interfaces.sol";

contract MplUserActions is IMplUserActions {

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    address public immutable override migrator;
    address public immutable override mpl;
    address public immutable override stsyrup;
    address public immutable override syrup;
    address public immutable override xmpl;

    /**************************************************************************************************************************************/
    /*** Constructor                                                                                                                    ***/
    /**************************************************************************************************************************************/

    constructor(address migrator_, address xmpl_, address stsyrup_) {
        address mpl_   = IRDTLike(xmpl_).asset();
        address syrup_ = IRDTLike(stsyrup_).asset();

        migrator = migrator_;
        mpl      = mpl_;
        syrup    = syrup_;
        xmpl     = xmpl_;
        stsyrup  = stsyrup_;

        require(ERC20Helper.approve(mpl_,   migrator_, type(uint256).max), "MUA:C:MPL_APPROVE");
        require(ERC20Helper.approve(syrup_, stsyrup_,  type(uint256).max), "MUA:C:SYRUP_APPROVE");
    }

    /**************************************************************************************************************************************/
    /*** External Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    // MPL -> SYRUP -> stSYRUP
    function migrateAndStake(address receiver_, uint256 mplAmount_) external override returns (uint256 stsyrupAmount_) {
        require(mplAmount_ > 0,                                                       "MUA:MAS:ZERO_AMOUNT");
        require(ERC20Helper.transferFrom(mpl, msg.sender, address(this), mplAmount_), "MUA:MAS:TRANSFER_FAIL");

        uint256 syrupAmount_ = _migrate(address(this), mplAmount_);
        stsyrupAmount_       = _stake(receiver_, syrupAmount_);

        emit Migrated(msg.sender, mpl, mplAmount_, receiver_, stsyrup, stsyrupAmount_);
    }

    // xMPL -> MPL -> SYRUP
    function redeemAndMigrate(address receiver_, uint256 xmplAmount_) external override returns (uint256 syrupAmount_) {
        require(xmplAmount_ > 0,                                                        "MUA:RAM:ZERO_AMOUNT");
        require(ERC20Helper.transferFrom(xmpl, msg.sender, address(this), xmplAmount_), "MUA:RAM:TRANSFER_FAIL");

        uint256 mplAmount_ = _redeem(address(this), xmplAmount_);
        syrupAmount_       = _migrate(receiver_, mplAmount_);

        emit Migrated(msg.sender, xmpl, xmplAmount_, receiver_, syrup, syrupAmount_);
    }

    // xMPL -> MPL -> SYRUP -> stSYRUP
    function redeemAndMigrateAndStake(address receiver_, uint256 xmplAmount_) external override returns (uint256 stsyrupAmount_) {
        require(xmplAmount_ > 0,                                                        "MUA:RAMAS:ZERO_AMOUNT");
        require(ERC20Helper.transferFrom(xmpl, msg.sender, address(this), xmplAmount_), "MUA:RAMAS:TRANSFER_FAIL");

        uint256 mplAmount_   = _redeem(address(this), xmplAmount_);
        uint256 syrupAmount_ = _migrate(address(this), mplAmount_);
        stsyrupAmount_       = _stake(receiver_, syrupAmount_);

        emit Migrated(msg.sender, xmpl, xmplAmount_, receiver_, stsyrup, stsyrupAmount_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _migrate(address receiver_, uint256 mplAmount_) internal returns (uint256 syrupAmount_) {
        syrupAmount_ = IMigratorLike(migrator).migrate(receiver_, mplAmount_);
    }

    function _redeem(address receiver_, uint256 xmplAmount_) internal returns (uint256 mplAmount_) {
        mplAmount_ = IRDTLike(xmpl).redeem(xmplAmount_, receiver_, address(this));
    }

    function _stake(address receiver_, uint256 syrupAmount_) internal returns (uint256 stsyrupAmount_) {
        stsyrupAmount_ = IRDTLike(stsyrup).deposit(syrupAmount_, receiver_);
    }

}
