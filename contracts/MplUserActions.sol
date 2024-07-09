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
    function migrateAndStake(address receiver_, uint256 mplIn_) external override returns (uint256 stsyrupOut_) {
        require(mplIn_ > 0,                                                       "MUA:MAS:ZERO_AMOUNT");
        require(ERC20Helper.transferFrom(mpl, msg.sender, address(this), mplIn_), "MUA:MAS:TRANSFER_FAIL");

        uint256 syrupAmount_ = _migrate(address(this), mplIn_);
        stsyrupOut_          = _stake(receiver_, syrupAmount_);

        emit Migrated(msg.sender, mpl, mplIn_, receiver_, stsyrup, stsyrupOut_);
    }

    // xMPL -> MPL -> SYRUP
    function redeemAndMigrate(address receiver_, uint256 xmplIn_) external override returns (uint256 syrupOut_) {
        require(xmplIn_ > 0,                                                        "MUA:RAM:ZERO_AMOUNT");
        require(ERC20Helper.transferFrom(xmpl, msg.sender, address(this), xmplIn_), "MUA:RAM:TRANSFER_FAIL");

        uint256 mplAmount_ = _redeem(address(this), xmplIn_);
        syrupOut_          = _migrate(receiver_, mplAmount_);

        emit Migrated(msg.sender, xmpl, xmplIn_, receiver_, syrup, syrupOut_);
    }

    // xMPL -> MPL -> SYRUP -> stSYRUP
    function redeemAndMigrateAndStake(address receiver_, uint256 xmplIn_) external override returns (uint256 stsyrupOut_) {
        require(xmplIn_ > 0,                                                        "MUA:RAMAS:ZERO_AMOUNT");
        require(ERC20Helper.transferFrom(xmpl, msg.sender, address(this), xmplIn_), "MUA:RAMAS:TRANSFER_FAIL");

        uint256 mplAmount_   = _redeem(address(this), xmplIn_);
        uint256 syrupAmount_ = _migrate(address(this), mplAmount_);
        stsyrupOut_          = _stake(receiver_, syrupAmount_);

        emit Migrated(msg.sender, xmpl, xmplIn_, receiver_, stsyrup, stsyrupOut_);
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function _migrate(address receiver_, uint256 mplIn_) internal returns (uint256 syrupOut_) {
        syrupOut_ = IMigratorLike(migrator).migrate(receiver_, mplIn_);
    }

    function _redeem(address receiver_, uint256 xmplIn_) internal returns (uint256 mplOut_) {
        mplOut_ = IRDTLike(xmpl).redeem(xmplIn_, receiver_, address(this));
    }

    function _stake(address receiver_, uint256 syrupIn_) internal returns (uint256 stsyrupOut_) {
        stsyrupOut_ = IRDTLike(stsyrup).deposit(syrupIn_, receiver_);
    }

}
