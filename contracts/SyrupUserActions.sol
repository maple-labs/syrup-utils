// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { ISyrupUserActions } from "./interfaces/ISyrupUserActions.sol";

import { IBalancerVaultLike, IPSMLike, ISDAILike } from "./interfaces/Interfaces.sol";

contract SyrupUserActions is ISyrupUserActions {

    address constant public override BAL_VAULT  = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant public override DAI        = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant public override PSM        = 0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A;
    address constant public override SDAI       = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant public override SYRUP_USDC = 0x80ac24aA929eaF5013f6436cdA2a7ba190f5Cc0b;
    address constant public override USDC       = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint256 constant public override PSM_PRECISION = 1e12;  // The PSM expected 1e18 minus the decimals of the gem (eg. 18 - 6 = 12)

    bytes32 immutable public override POOL_ID;

    constructor(bytes32 poolId_) {
        POOL_ID = poolId_;

        require(ERC20Helper.approve(SYRUP_USDC, BAL_VAULT, type(uint256).max), "SUA:C:SYRUP_APPROVE_FAIL");
        require(ERC20Helper.approve(DAI, PSM, type(uint256).max),              "SUA:C:DAI_APPROVE_FAIL");
    }

    function swapToDai(uint256 syrupUsdcAmountIn_, uint256 minDaiOut_) external override returns (uint256 daiOut_) {
        // 1. Pull SyrupUSDC from the user
        require(ERC20Helper.transferFrom(SYRUP_USDC, msg.sender, address(this), syrupUsdcAmountIn_), "SAU:STD:TRANSFER_FROM_FAILED");

        // 2. Swap into sDAI
        uint256 sDAIAmount = _swapViaBalancer(syrupUsdcAmountIn_);

        // 3. Redeem sDAI for DAI
        daiOut_ = _redeemForDAI(sDAIAmount);

        require(daiOut_ >= minDaiOut_,                          "SAU:STD:INSUFFICIENT_DAI");
        require(ERC20Helper.transfer(DAI, msg.sender, daiOut_), "SAU:STD:TRANSFER_FAILED");
    }

    function swapToUsdc(uint256 syrupUsdcAmountIn_, uint256 minUsdcOut_) external override returns (uint256 usdcOut_) {
        // 1. Pull SyrupUSDC from the user
        require(ERC20Helper.transferFrom(SYRUP_USDC, msg.sender, address(this), syrupUsdcAmountIn_), "SUA:STU:TRANSFER_FROM_FAILED");

        // 2. Swap to sDAI
        uint256 sDAIAmount = _swapViaBalancer(syrupUsdcAmountIn_);

        // 3. Redeem sDAI for DAI
        uint256 daiOut = _redeemForDAI(sDAIAmount);

        // 4. Swap DAI for USDC using the PSM
        usdcOut_ = _swapDaiForUsdc(daiOut, msg.sender, minUsdcOut_);
    }

    function _swapDaiForUsdc(uint256 daiAmount_, address receiver_, uint256 minUsdcOut_) internal returns (uint256 amountOut_) {
        IPSMLike psm = IPSMLike(PSM);
        // Calculate the exact amount of gems we expect to receive given this amount of assets
        // We are reversing the calculation at
        // https://github.com/makerdao/dss-psm/blob/222c96d4047e76680ed6803f07dd61aa2590e42b/src/psm.sol#L121
        // Note: Due to rounding, this may leave dai dust in the contract
        amountOut_ = daiAmount_ * 1e18 / (PSM_PRECISION * (1e18 + psm.tout()));
        require(amountOut_ >= minUsdcOut_, "SUA:SDU:INSUFFICIENT_AMOUNT_OUT");
        psm.buyGem(receiver_, amountOut_);
    }

    function _swapViaBalancer(uint256 amountIn_) internal returns (uint256 sDai_) {
        IBalancerVaultLike.FundManagement memory funds = IBalancerVaultLike.FundManagement({
            sender:              address(this),
            fromInternalBalance: false,
            recipient:           address(this),
            toInternalBalance:   false
        });

        IBalancerVaultLike.SingleSwap memory swap = IBalancerVaultLike.SingleSwap({
            poolId:   POOL_ID,
            kind:     IBalancerVaultLike.SwapKind.GIVEN_IN,
            assetIn:  SYRUP_USDC,
            assetOut: SDAI,
            amount:   amountIn_,
            userData: new bytes(0)
        });

        sDai_ = IBalancerVaultLike(BAL_VAULT).swap({
            singleSwap: swap,
            funds:      funds,
            limit:      0,
            deadline:   block.timestamp
        });
    }

    function _redeemForDAI(uint256 amount_) internal returns (uint256 dai_) {
        dai_ = ISDAILike(SDAI).redeem(amount_, address(this), address(this));
    }

}