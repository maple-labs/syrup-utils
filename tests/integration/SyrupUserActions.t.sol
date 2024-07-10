// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test, Vm } from "../../modules/forge-std/src/Test.sol";

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

    function _getPermitDigest(address asset_, address owner_, address spender_, uint256 value_, uint256 nonce_, uint256 deadline_)
        internal view returns (bytes32 digest_)
    {
        IERC20Like asset = IERC20Like(asset_);

        return keccak256(
            abi.encodePacked(
                '\x19\x01',
                asset.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(asset.PERMIT_TYPEHASH(), owner_, spender_, value_, nonce_, deadline_))
            )
        );
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

    uint256 syrupUsdcIn = 1e6;

    IERC20Like usdc      = IERC20Like(USDC);
    IERC20Like syrupUsdc = IERC20Like(SYRUP_USDC);

    Vm.Wallet accountWallet = vm.createWallet("account");

    function setUp() public override {
        super.setUp();

        _mintSyrupUsdc(address(account), syrupUsdcIn);
    }

    function testFork_swapToUsdc_noApproval() external {
        vm.expectRevert("SUA:STU:TRANSFER_FROM_FAILED");
        syrupUserActions.swapToUsdc(syrupUsdcIn, 0);
    }

    function testFork_swapToUsdcWithPermit_expired() external {
        uint256 deadline  = block.timestamp - 1 seconds;
        address depositor = accountWallet.addr;

        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(accountWallet, _getPermitDigest({
            asset_:    address(syrupUsdc),
            owner_:    depositor,
            spender_:  address(syrupUserActions),
            value_:    syrupUsdcIn,
            nonce_:    0,
            deadline_: deadline
            })
        );

        vm.expectRevert("ERC20:P:EXPIRED");
        vm.prank(account);
        syrupUserActions.swapToUsdcWithPermit(syrupUsdcIn, 0, deadline, v, r, s);
    }

    function testFork_swapToUsdcWithPermit_invalidSignatureDueToInvalidNonce() external {
        uint256 deadline  = block.timestamp;
        address depositor = accountWallet.addr;

        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(accountWallet, _getPermitDigest({
            asset_:    address(syrupUsdc),
            owner_:    depositor,
            spender_:  address(syrupUserActions),
            value_:    syrupUsdcIn,
            nonce_:    1,
            deadline_: deadline
            })
        );

        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        vm.prank(account);
        syrupUserActions.swapToUsdcWithPermit(syrupUsdcIn, 0, deadline, v, r, s);
    }

    function testFork_swapToUsdcWithPermit_insufficientPermitAmount() external {
        uint256 deadline  = block.timestamp;
        address depositor = accountWallet.addr;

        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(accountWallet, _getPermitDigest({
            asset_:    address(syrupUsdc),
            owner_:    depositor,
            spender_:  address(syrupUserActions),
            value_:    syrupUsdcIn - 1,
            nonce_:    0,
            deadline_: deadline
            })
        );

        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        vm.prank(account);
        syrupUserActions.swapToUsdcWithPermit(syrupUsdcIn, 0, deadline, v, r, s);
    }

    function testFork_swapToUsdc_insufficientBalance() external {
        // Burn syrupUSDC
        vm.prank(account);
        syrupUsdc.transfer(address(0), 1);

        syrupUsdc.approve(address(syrupUserActions), syrupUsdcIn);

        vm.expectRevert("SUA:STU:TRANSFER_FROM_FAILED");
        syrupUserActions.swapToUsdc(syrupUsdcIn, 0);
    }

    function testFork_swapToUsdcWithPermit_insufficientBalance() external {
        uint256 deadline  = block.timestamp;
        address depositor = accountWallet.addr;

        // Burn syrupUSDC
        vm.prank(account);
        syrupUsdc.transfer(address(0), 1);

        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(accountWallet, _getPermitDigest({
            asset_:    address(syrupUsdc),
            owner_:    depositor,
            spender_:  address(syrupUserActions),
            value_:    syrupUsdcIn,
            nonce_:    0,
            deadline_: deadline
            })
        );

        vm.expectRevert("SUA:STUWP:TRANSFER_FROM_FAILED");
        vm.prank(account);
        syrupUserActions.swapToUsdcWithPermit(syrupUsdcIn, 0, deadline, v, r, s);
    }

    function testFork_swapToUsdc_notEnoughOut() external {
        _mintSyrupUsdc(address(account), syrupUsdcIn);

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), syrupUsdcIn);

        vm.expectRevert("SUA:SDU:INSUFFICIENT_AMOUNT_OUT");
        vm.prank(account);
        syrupUserActions.swapToUsdc(syrupUsdcIn, 100e6);
    }

    function testFork_swapToUsdcWithPermit_notEnoughOut() external {
        uint256 deadline  = block.timestamp;
        address depositor = accountWallet.addr;

        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(accountWallet, _getPermitDigest({
            asset_:    address(syrupUsdc),
            owner_:    depositor,
            spender_:  address(syrupUserActions),
            value_:    syrupUsdcIn,
            nonce_:    0,
            deadline_: deadline
            })
        );

        vm.expectRevert("SUA:SDU:INSUFFICIENT_AMOUNT_OUT");
        vm.prank(account);
        syrupUserActions.swapToUsdcWithPermit(syrupUsdcIn, 100e6, deadline, v, r, s);
    }

    function testFork_swapToUsdc_success() public {
        uint256 poolOutput = IPoolLike(SYRUP_USDC).convertToExitAssets(syrupUsdcIn);
        uint256 minOutput  = poolOutput * 0.995e18 / 1e18;

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), syrupUsdcIn);

        assertEq(syrupUsdc.balanceOf(address(account)),          syrupUsdcIn);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               0);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        vm.prank(account);
        uint256 usdcOut = syrupUserActions.swapToUsdc(syrupUsdcIn, minOutput);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               usdcOut);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        assertTrue(usdcOut >= minOutput);
    }

    function testFork_swapToUsdcWithPermit_success() external {
        address depositor  = accountWallet.addr;
        uint256 deadline   = block.timestamp;
        uint256 poolOutput = IPoolLike(SYRUP_USDC).convertToExitAssets(syrupUsdcIn);
        uint256 minOutput  = poolOutput * 0.995e18 / 1e18;

        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(accountWallet, _getPermitDigest({
            asset_:    address(syrupUsdc),
            owner_:    depositor,
            spender_:  address(syrupUserActions),
            value_:    syrupUsdcIn ,
            nonce_:    0,
            deadline_: deadline
            })
        );

        assertEq(syrupUsdc.balanceOf(address(account)),          syrupUsdcIn);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               0);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        vm.prank(account);
        uint256 usdcOut = syrupUserActions.swapToUsdcWithPermit(syrupUsdcIn, minOutput, deadline, v, r, s);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               usdcOut);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        assertTrue(usdcOut >= minOutput);
    }

    function testForkFuzz_swapToUsdc(uint256 syrupUsdcIn_, uint256 slippage_) external {
        // Burn existing amount of syrupUsdc in the account
        vm.prank(account);
        syrupUsdc.transfer(address(0), syrupUsdcIn);

        // Increase this value once the balancer pool has more liquidity
        syrupUsdcIn = bound(syrupUsdcIn_, 2, 400e6);
        slippage_   = bound(slippage_, 20, 100);  // From 20 to 100 bps

        uint256 minUsdcOut = syrupUsdcIn * (10000 - slippage_) / 10000;

        _mintSyrupUsdc(address(account), syrupUsdcIn);

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), syrupUsdcIn);

        assertEq(syrupUsdc.balanceOf(address(account)),          syrupUsdcIn);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               0);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        vm.prank(account);
        uint256 usdcOut = syrupUserActions.swapToUsdc(syrupUsdcIn, minUsdcOut);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               usdcOut);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        assertTrue(usdcOut >= minUsdcOut);
    }

    function testForkFuzz_swapToUsdcWithPermit_success(uint256 amountIn_, uint256 slippage_) external {
        // Burn existing amount of syrupUsdc in the account
        vm.prank(account);
        syrupUsdc.transfer(address(0), syrupUsdcIn);

        address depositor  = accountWallet.addr;
        uint256 deadline   = block.timestamp;

        syrupUsdcIn = bound(amountIn_, 2, 400e6);
        slippage_   = bound(slippage_, 20, 100);  // From 20 to 100 bps

        uint256 minUsdcOut = syrupUsdcIn * (10000 - slippage_) / 10000;

        _mintSyrupUsdc(address(account), syrupUsdcIn);

        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(accountWallet, _getPermitDigest({
            asset_:    address(syrupUsdc),
            owner_:    depositor,
            spender_:  address(syrupUserActions),
            value_:    syrupUsdcIn ,
            nonce_:    0,
            deadline_: deadline
            })
        );

        assertEq(syrupUsdc.balanceOf(address(account)),          syrupUsdcIn);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               0);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        vm.prank(account);
        uint256 usdcOut = syrupUserActions.swapToUsdcWithPermit(syrupUsdcIn, minUsdcOut, deadline, v, r, s);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(usdc.balanceOf(address(account)),               usdcOut);
        assertEq(usdc.balanceOf(address(syrupUserActions)),      0);

        assertTrue(usdcOut >= minUsdcOut);
    }

}

contract SyrupUserActionsSwapToDaiTests is SyrupUserActionsTestBase {

    address account = makeAddr("account");

    uint256 syrupUsdcIn = 1e6;

    IERC20Like dai       = IERC20Like(DAI);
    IERC20Like syrupUsdc = IERC20Like(SYRUP_USDC);

    function testFork_swapToDai_noApproval() external {
        _mintSyrupUsdc(address(account), syrupUsdcIn);

        vm.expectRevert("SAU:STD:TRANSFER_FROM_FAILED");
        syrupUserActions.swapToDai(syrupUsdcIn, 0);
    }

    function testFork_swapToDai_insufficientBalance() external {
        _mintSyrupUsdc(address(account), syrupUsdcIn - 1);

        syrupUsdc.approve(address(syrupUserActions), syrupUsdcIn);

        vm.expectRevert("SAU:STD:TRANSFER_FROM_FAILED");
        syrupUserActions.swapToDai(syrupUsdcIn, 0);
    }

    function testFork_swapToDai_notEnoughOut() external {
        _mintSyrupUsdc(address(account), syrupUsdcIn);

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), syrupUsdcIn);

        vm.expectRevert("SAU:STD:INSUFFICIENT_DAI");
        vm.prank(account);
        syrupUserActions.swapToDai(syrupUsdcIn, 100e18);
    }

    function testFork_swapToDai_success() public {
        _mintSyrupUsdc(address(account), syrupUsdcIn);

        uint256 poolOutput = IPoolLike(SYRUP_USDC).convertToExitAssets(syrupUsdcIn);
        uint256 minDaiOut  = poolOutput * 0.995e18 / 1e18;

        uint256 initialSdaiBalance = IERC20Like(SDAI).balanceOf(address(BAL_VAULT));

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), syrupUsdcIn);

        assertEq(syrupUsdc.balanceOf(address(account)),          syrupUsdcIn);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(dai.balanceOf(address(account)),                0);
        assertEq(dai.balanceOf(address(syrupUserActions)),       0);

        vm.prank(account);
        uint256 daiOut = syrupUserActions.swapToDai(syrupUsdcIn, minDaiOut);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(dai.balanceOf(address(account)),                daiOut);
        assertEq(dai.balanceOf(address(syrupUserActions)),       0);

        assertTrue(initialSdaiBalance > IERC20Like(SDAI).balanceOf(address(BAL_VAULT)));

        assertTrue(daiOut >= minDaiOut);
    }

    function testForkFuzz_swapToDai(uint256 syrupUsdcIn_, uint256 slippage_) external {
        // Increase this value once the balancer pool has more liquidity
        syrupUsdcIn = bound(syrupUsdcIn_, 2, 400e6);
        slippage_   = bound(slippage_, 10, 100);  // From 10 to 100 bps

        uint256 minDaiOut = syrupUsdcIn * (10000 - slippage_) / 10000;

        uint256 initialSdaiBalance = IERC20Like(SDAI).balanceOf(address(BAL_VAULT));

        _mintSyrupUsdc(address(account), syrupUsdcIn);

        vm.prank(account);
        syrupUsdc.approve(address(syrupUserActions), syrupUsdcIn);

        assertEq(syrupUsdc.balanceOf(address(account)),          syrupUsdcIn);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(dai.balanceOf(address(account)),                0);
        assertEq(dai.balanceOf(address(syrupUserActions)),       0);

        vm.prank(account);
        uint256 daiOut = syrupUserActions.swapToDai(syrupUsdcIn, minDaiOut);

        assertEq(syrupUsdc.balanceOf(address(account)),          0);
        assertEq(syrupUsdc.balanceOf(address(syrupUserActions)), 0);
        assertEq(dai.balanceOf(address(account)),                daiOut);
        assertEq(dai.balanceOf(address(syrupUserActions)),       0);

        assertTrue(initialSdaiBalance > IERC20Like(SDAI).balanceOf(address(BAL_VAULT)));

        assertTrue(daiOut >= minDaiOut);
    }

}
