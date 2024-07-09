// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test } from "../../modules/forge-std/src/Test.sol";

import { IERC20Like, IPoolLike } from "../../contracts/interfaces/Interfaces.sol";
import { SyrupUserActions }      from "../../contracts/SyrupUserActions.sol";

contract SyrupUserActionsTestBase is Test {

    address constant BAL_VAULT    = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant DAI          = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant SDAI         = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant SYRUP_USDC   = 0x80ac24aA929eaF5013f6436cdA2a7ba190f5Cc0b;
    address constant SYRUP_SOURCE = 0xAdA1fc89b42F15A1Ce5395456CF4E0A90A9e8EfE;
    address constant USDC         = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_SOURCE  = 0x4B16c5dE96EB2117bBE5fd171E4d203624B014aa;

    bytes32 constant POOL_ID = 0x48a5bfb5bd44345db0b31fa4b5a204890695c9b4000000000000000000000697;

    SyrupUserActions syrupUserActions;

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20184000);

        syrupUserActions = new SyrupUserActions(POOL_ID);
    }

    function _mintUSDC(address to_, uint256 amount_) internal {
        vm.prank(USDC_SOURCE);
        IERC20Like(USDC).transfer(to_, amount_);
    }

    function _mintSyrupUsdc(address to_, uint256 amount_) internal {
        vm.prank(SYRUP_SOURCE);
        IERC20Like(SYRUP_USDC).transfer(to_, amount_);
    }

}

contract SyrupUserActionsConstructorTests is SyrupUserActionsTestBase {

    function testFork_constructor() external {

        syrupUserActions = new SyrupUserActions(POOL_ID);

        assertEq(syrupUserActions.BAL_VAULT(),     0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        assertEq(syrupUserActions.DAI(),           0x6B175474E89094C44Da98b954EedeAC495271d0F);
        assertEq(syrupUserActions.PSM(),           0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A);
        assertEq(syrupUserActions.SYRUP_USDC(),    0x80ac24aA929eaF5013f6436cdA2a7ba190f5Cc0b);
        assertEq(syrupUserActions.USDC(),          0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        assertEq(syrupUserActions.POOL_ID(),       POOL_ID);
        assertEq(syrupUserActions.PSM_PRECISION(), 1e12);
    }

}

contract SyrupUserActionsSwapToUsdcTests is SyrupUserActionsTestBase {

    address account = makeAddr("account");

    uint256 amount = 1e6;

    IERC20Like usdc      = IERC20Like(USDC);
    IERC20Like syrupUsdc = IERC20Like(SYRUP_USDC);

    function testFork_swapToUsdc_noApproval() external {
        _mintSyrupUsdc(address(account), amount);

        vm.expectRevert("SUA:STU:TRANSFER_FROM_FAILED");
        syrupUserActions.swapToUsdc(amount, 0);
    }

    function testFork_swapToUsdc_insufficientBalance() external {
        _mintSyrupUsdc(address(account), amount - 1);

        syrupUsdc.approve(address(syrupUserActions), amount);

        vm.expectRevert("SUA:STU:TRANSFER_FROM_FAILED");
        syrupUserActions.swapToUsdc(amount, 0);
    }

    function testFork_swapToUsdc_notEnoughOut() external {
        _mintSyrupUsdc(address(account), amount);

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), amount);

        vm.expectRevert("SUA:SDU:INSUFFICIENT_AMOUNT_OUT");
        vm.prank(account);
        syrupUserActions.swapToUsdc(amount, 100e6);
    }

    function testFork_swapToUsdc_success() public {
        _mintSyrupUsdc(address(account), amount);

        uint256 poolOutput = IPoolLike(SYRUP_USDC).convertToExitAssets(amount);
        uint256 minOutput  = poolOutput * 0.995e18 / 1e18;

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), amount);

        assertEq(syrupUsdc.balanceOf(address(account)),          amount);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               0);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        vm.prank(account);
        uint256 usdcOut = syrupUserActions.swapToUsdc(amount, minOutput);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               usdcOut);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);
    }

    function testForkFuzz_swapToUsdc(uint256 amount_, uint256 slippage_) external {
        // Increase this value once the balancer pool has more liquidity
        amount    = bound(amount_, 2, 400e6);
        slippage_ = bound(slippage_, 20, 100);  // From 20 to 100 bps

        uint256 minAmountOut = amount * (10000 - slippage_) / 10000;

        _mintSyrupUsdc(address(account), amount);

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), amount);

        assertEq(syrupUsdc.balanceOf(address(account)),          amount);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               0);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        vm.prank(account);
        uint256 usdcOut = syrupUserActions.swapToUsdc(amount, minAmountOut);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               usdcOut);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);
    }

}

contract SyrupUserActionsSwapToDaiTests is SyrupUserActionsTestBase {

    address account = makeAddr("account");

    uint256 amount = 1e6;

    IERC20Like dai       = IERC20Like(DAI);
    IERC20Like syrupUsdc = IERC20Like(SYRUP_USDC);

    function testFork_swapToDai_noApproval() external {
        _mintSyrupUsdc(address(account), amount);

        vm.expectRevert("SAU:STD:TRANSFER_FROM_FAILED");
        syrupUserActions.swapToDai(amount, 0);
    }

    function testFork_swapToDai_insufficientBalance() external {
        _mintSyrupUsdc(address(account), amount - 1);

        syrupUsdc.approve(address(syrupUserActions), amount);

        vm.expectRevert("SAU:STD:TRANSFER_FROM_FAILED");
        syrupUserActions.swapToDai(amount, 0);
    }

    function testFork_swapToDai_notEnoughOut() external {
        _mintSyrupUsdc(address(account), amount);

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), amount);

        vm.expectRevert("SAU:STD:INSUFFICIENT_DAI");
        vm.prank(account);
        syrupUserActions.swapToDai(amount, 100e18);
    }

    function testFork_swapToDai_success() public {
        _mintSyrupUsdc(address(account), amount);

        uint256 poolOutput = IPoolLike(SYRUP_USDC).convertToExitAssets(amount);
        uint256 minOutput  = poolOutput * 0.995e18 / 1e18;

        uint256 initialSdaiBalance = IERC20Like(SDAI).balanceOf(address(BAL_VAULT));

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), amount);

        assertEq(syrupUsdc.balanceOf(address(account)),          amount);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(dai.balanceOf(address(account)),                0);
        assertEq(dai.balanceOf(address(syrupUserActions)),       0);

        vm.prank(account);
        uint256 usdcOut = syrupUserActions.swapToDai(amount, minOutput);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(dai.balanceOf(address(account)),                usdcOut);
        assertEq(dai.balanceOf(address(syrupUserActions)),       0);

        assertTrue(initialSdaiBalance > IERC20Like(SDAI).balanceOf(address(BAL_VAULT)));
    }

    function testForkFuzz_swapToDai(uint256 amount_, uint256 slippage_) external {
        // Increase this value once the balancer pool has more liquidity
        amount    = bound(amount_, 2, 400e6);
        slippage_ = bound(slippage_, 10, 100);  // From 10 to 100 bps

        uint256 minAmountOut = amount * (10000 - slippage_) / 10000;

        uint256 initialSdaiBalance = IERC20Like(SDAI).balanceOf(address(BAL_VAULT));

        _mintSyrupUsdc(address(account), amount);

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), amount);

        assertEq(syrupUsdc.balanceOf(address(account)),          amount);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(dai.balanceOf(address(account)),                0);
        assertEq(dai.balanceOf(address(syrupUserActions)),       0);

        vm.prank(account);
        uint256 usdcOut = syrupUserActions.swapToDai(amount, minAmountOut);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(dai.balanceOf(address(account)),                usdcOut);
        assertEq(dai.balanceOf(address(syrupUserActions)),       0);

        assertTrue(initialSdaiBalance > IERC20Like(SDAI).balanceOf(address(BAL_VAULT)));
    }

}
