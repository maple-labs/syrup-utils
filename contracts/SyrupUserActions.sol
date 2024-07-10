// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { ISyrupUserActions } from "./interfaces/ISyrupUserActions.sol";

import { IBalancerVaultLike, IERC20Like, IPSMLike, ISdaiLike } from "./interfaces/Interfaces.sol";

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

    function swapToDai(uint256 syrupUsdcIn_, uint256 minDaiOut_) external override returns (uint256 daiOut_) {
        // 1. Pull SyrupUSDC from the user
        require(ERC20Helper.transferFrom(SYRUP_USDC, msg.sender, address(this), syrupUsdcIn_), "SAU:STD:TRANSFER_FROM_FAILED");

        // 2. Swap into sDAI
        uint256 sdaiAmount = _swapViaBalancer(syrupUsdcIn_);

        // 3. Redeem sDAI for DAI
        daiOut_ = _redeemForDai(sdaiAmount);

        require(daiOut_ >= minDaiOut_,                          "SAU:STD:INSUFFICIENT_DAI");
        require(ERC20Helper.transfer(DAI, msg.sender, daiOut_), "SAU:STD:TRANSFER_FAILED");
    }

    function swapToDaiWithPermit(
        uint256 syrupUsdcIn_, 
        uint256 minDaiOut_, 
        uint256 deadline_, 
        uint8   v_, 
        bytes32 r_, 
        bytes32 s_
    ) 
        external override returns (uint256 daiOut_) 
    {
        // 1. Permit the use of SyrupUSDC from the user
        _permit(SYRUP_USDC, deadline_, syrupUsdcIn_, v_, r_, s_);

        // 2. Pull SyrupUSDC from the user
        require(ERC20Helper.transferFrom(SYRUP_USDC, msg.sender, address(this), syrupUsdcIn_), "SUA:STDWP:TRANSFER_FROM_FAILED");

        // 3. Swap to sDAI
        uint256 sdaiAmount = _swapViaBalancer(syrupUsdcIn_);

        // 4. Redeem sDAI for DAI  
        daiOut_ = _redeemForDai(sdaiAmount);

        require(daiOut_ >= minDaiOut_,                          "SAU:STDWP:INSUFFICIENT_DAI_OUT");
        require(ERC20Helper.transfer(DAI, msg.sender, daiOut_), "SAU:STDWP:TRANSFER_FAILED");
    }

    function swapToUsdc(uint256 syrupUsdcIn_, uint256 minUsdcOut_) external override returns (uint256 usdcOut_) {
        // 1. Pull SyrupUSDC from the user
        require(ERC20Helper.transferFrom(SYRUP_USDC, msg.sender, address(this), syrupUsdcIn_), "SUA:STU:TRANSFER_FROM_FAILED");

        // 2. Swap to sDAI
        uint256 sdaiAmount = _swapViaBalancer(syrupUsdcIn_);

        // 3. Redeem sDAI for DAI
        uint256 daiOut = _redeemForDai(sdaiAmount);

        // 4. Swap DAI for USDC using the PSM
        usdcOut_ = _swapDaiForUsdc(daiOut, msg.sender, minUsdcOut_);
    }

     function swapToUsdcWithPermit(
        uint256 syrupUsdcIn_,
        uint256 minUsdcOut_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external override returns (uint256 usdcOut_)
    {
        // 1. Permit the use of SyrupUSDC from the user
        _permit(SYRUP_USDC, deadline_, syrupUsdcIn_, v_, r_, s_);

        // 2. Pull SyrupUSDC from the user
        require(ERC20Helper.transferFrom(SYRUP_USDC, msg.sender, address(this), syrupUsdcIn_), "SUA:STUWP:TRANSFER_FROM_FAILED");

        // 3. Swap to sDAI
        uint256 sdaiAmount = _swapViaBalancer(syrupUsdcIn_);

        // 4. Redeem sDAI to DAI
        uint256 daiOut = _redeemForDai(sdaiAmount);

        // 5. Swap DAI for USDC using the PSM
        usdcOut_ = _swapDaiForUsdc(daiOut, msg.sender, minUsdcOut_);
    }

    function _permit(address asset_, uint256 deadline_, uint256 amount_, uint8 v_, bytes32 r_, bytes32 s_) internal {
        uint256 allowance_ = IERC20Like(asset_).allowance(msg.sender, address(this));

        if (allowance_ < amount_) {
            IERC20Like(asset_).permit(msg.sender, address(this), amount_, deadline_, v_, r_, s_);
        }
    }

    function _redeemForDai(uint256 sdaiIn) internal returns (uint256 daiOut_) {
        daiOut_ = ISdaiLike(SDAI).redeem(sdaiIn, address(this), address(this));
    }

    function _swapDaiForUsdc(uint256 daiIn_, address receiver_, uint256 minUsdcOut_) internal returns (uint256 usdcOut_) {
        IPSMLike psm = IPSMLike(PSM);
        // Calculate the exact amount of gems we expect to receive given this amount of assets
        // We are reversing the calculation at
        // https://github.com/makerdao/dss-psm/blob/222c96d4047e76680ed6803f07dd61aa2590e42b/src/psm.sol#L121
        // Note: Due to rounding, this may leave dai dust in the contract
        usdcOut_ = daiIn_ * 1e18 / (PSM_PRECISION * (1e18 + psm.tout()));
        require(usdcOut_ >= minUsdcOut_, "SUA:SDU:INSUFFICIENT_AMOUNT_OUT");
        psm.buyGem(receiver_, usdcOut_);
    }

    function _swapViaBalancer(uint256 syrupUsdcIn_) internal returns (uint256 sdaiOut_) {
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
            amount:   syrupUsdcIn_,
            userData: new bytes(0)
        });

        sdaiOut_ = IBalancerVaultLike(BAL_VAULT).swap({
            singleSwap: swap,
            funds:      funds,
            limit:      0,
            deadline:   block.timestamp
        });
    }

}
