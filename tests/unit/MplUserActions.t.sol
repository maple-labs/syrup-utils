// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test } from "../../modules/forge-std/src/Test.sol";

import { MplUserActions } from "../../contracts/MplUserActions.sol";

import { MockERC20, MockMigrator, MockRDT } from "../utils/Mocks.sol";

contract MplUserActionsTestBase is Test {

    event Migrated(
        address indexed sender,
        address assetSent,
        uint256 amountSent,
        address indexed receiver,
        address assetReceived,
        uint256 amountReceived
    );

    address sender   = makeAddr("sender");
    address receiver = makeAddr("receiver");

    uint8   decimals = 18;
    uint256 scalar   = 100;

    uint256 xmplIn     = 15e18;
    uint256 mplIn      = xmplIn;
    uint256 syrupOut   = mplIn * scalar;
    uint256 stsyrupOut = syrupOut;

    MockMigrator migrator;
    MockERC20    mpl;
    MockERC20    syrup;
    MockRDT      xmpl;
    MockRDT      stsyrup;

    MplUserActions actions;

    function setUp() public virtual {
        mpl      = new MockERC20("Maple Token", "MPL", decimals);
        syrup    = new MockERC20("Syrup", "SYRUP", decimals);
        xmpl     = new MockRDT("xMPL", "xMPL", decimals, mpl);
        stsyrup  = new MockRDT("Staked Syrup", "stSYRUP", decimals, syrup);
        migrator = new MockMigrator(mpl, syrup, scalar);

        actions = new MplUserActions(address(migrator), address(xmpl), address(stsyrup));
    }

    function assertBalances(
        address[6] memory accounts,
        uint256[6] memory mpls,
        uint256[6] memory xmpls,
        uint256[6] memory syrups,
        uint256[6] memory stsyrups
    )
        internal view
    {
        for (uint256 i; i < accounts.length; i++) {
            assertEq(mpl.balanceOf(address(accounts[i])),     mpls[i]);
            assertEq(xmpl.balanceOf(address(accounts[i])),    xmpls[i]);
            assertEq(syrup.balanceOf(address(accounts[i])),   syrups[i]);
            assertEq(stsyrup.balanceOf(address(accounts[i])), stsyrups[i]);
        }
    }

}

contract MplUserActionsConstructorTests is MplUserActionsTestBase {

    function test_constructor() external {
        actions = new MplUserActions(address(migrator), address(xmpl), address(stsyrup));

        assertEq(actions.migrator(), address(migrator));
        assertEq(actions.mpl(),      address(mpl));
        assertEq(actions.syrup(),    address(syrup));
        assertEq(actions.xmpl(),     address(xmpl));
        assertEq(actions.stsyrup(),  address(stsyrup));

        assertEq(mpl.allowance(address(actions),   address(migrator)), type(uint256).max);
        assertEq(syrup.allowance(address(actions), address(stsyrup)),  type(uint256).max);
    }

}

contract MplUserActionsMigrateAndStakeTests is MplUserActionsTestBase {

    function test_migrateAndStake_zeroAmount() external {
        vm.prank(sender);
        vm.expectRevert("MUA:MAS:ZERO_AMOUNT");
        actions.migrateAndStake(receiver, 0);
    }

    function test_migrateAndStake_insufficientApproval() external {
        mpl.mint(sender, mplIn);

        vm.prank(sender);
        mpl.approve(address(actions), mplIn - 1);

        vm.prank(sender);
        vm.expectRevert("MUA:MAS:TRANSFER_FAIL");
        actions.migrateAndStake(receiver, mplIn);
    }

    function test_migrateAndStake_insufficientBalance() external {
        mpl.mint(sender, mplIn - 1);

        vm.prank(sender);
        mpl.approve(address(actions), mplIn);

        vm.prank(sender);
        vm.expectRevert("MUA:MAS:TRANSFER_FAIL");
        actions.migrateAndStake(receiver, mplIn);
    }

    function test_migrateAndStake_differentReceiver() external {
        mpl.mint(sender, mplIn);

        vm.prank(sender);
        mpl.approve(address(actions), mplIn);

        vm.expectEmit();
        emit Migrated(sender, address(mpl), mplIn, receiver, address(stsyrup), stsyrupOut);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       uint256(0),        uint256(0),        mplIn,           uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)]
        });

        vm.prank(sender);
        actions.migrateAndStake(receiver, mplIn);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       mplIn,             uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      syrupOut,         uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        stsyrupOut,        uint256(0),      uint256(0),       uint256(0)]
        });
    }

    function test_migrateAndStake_sameReceiver() external {
        mpl.mint(receiver, mplIn);

        vm.prank(receiver);
        mpl.approve(address(actions), mplIn);

        vm.expectEmit();
        emit Migrated(receiver, address(mpl), mplIn, receiver, address(stsyrup), stsyrupOut);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       uint256(0),        mplIn,             uint256(0),      uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)]
        });

        vm.prank(receiver);
        actions.migrateAndStake(receiver, mplIn);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       mplIn,             uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      syrupOut,         uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        stsyrupOut,        uint256(0),      uint256(0),       uint256(0)]
        });
    }

    function testFuzz_migrateAndStake() external {
        // TODO: Fuzz: sender, receiver, amounts, exchange rates (scalars).
    }

}

contract MplUserActionsRedeemAndMigrateTests is MplUserActionsTestBase {

    function test_redeemAndMigrate_zeroAmount() external {
        vm.prank(sender);
        vm.expectRevert("MUA:RAM:ZERO_AMOUNT");
        actions.redeemAndMigrate(receiver, 0);
    }

    function test_redeemAndMigrate_insufficientApproval() external {
        xmpl.mint(sender, xmplIn);

        vm.prank(sender);
        xmpl.approve(address(actions), xmplIn - 1);

        vm.prank(sender);
        vm.expectRevert("MUA:RAM:TRANSFER_FAIL");
        actions.redeemAndMigrate(receiver, xmplIn);
    }

    function test_redeemAndMigrate_insufficientBalance() external {
        xmpl.mint(sender, xmplIn - 1);

        vm.prank(sender);
        xmpl.approve(address(actions), xmplIn);

        vm.prank(sender);
        vm.expectRevert("MUA:RAM:TRANSFER_FAIL");
        actions.redeemAndMigrate(receiver, xmplIn);
    }

    function test_redeemAndMigrate_differentReceiver() external {
        mpl.mint(address(xmpl),    mplIn);
        xmpl.mint(address(sender), xmplIn);

        vm.prank(sender);
        xmpl.approve(address(actions), xmplIn);

        vm.expectEmit();
        emit Migrated(sender, address(xmpl), xmplIn, receiver, address(syrup), syrupOut);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       mplIn],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        xmplIn,          uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)]
        });

        vm.prank(sender);
        actions.redeemAndMigrate(receiver, xmplIn);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       mplIn,             uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        syrupOut,          uint256(0),      uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)]
        });
    }

    function test_redeemAndMigrate_sameReceiver() external {
        mpl.mint(address(xmpl),      mplIn);
        xmpl.mint(address(receiver), xmplIn);

        vm.prank(receiver);
        xmpl.approve(address(actions), xmplIn);

        vm.expectEmit();
        emit Migrated(receiver, address(xmpl), xmplIn, receiver, address(syrup), syrupOut);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       mplIn],
            xmpls:    [uint256(0),       uint256(0),        xmplIn,            uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)]
        });

        vm.prank(receiver);
        actions.redeemAndMigrate(receiver, xmplIn);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       mplIn,             uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        syrupOut,          uint256(0),      uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)]
        });
    }

    function testFuzz_redeemAndMigrate() external {
        // TODO: Fuzz: sender, receiver, amounts, exchange rates (scalars).
    }

}

contract MplUserActionsRedeemAndMigrateAndStakeTests is MplUserActionsTestBase {

    function test_redeemAndMigrateAndStake_zeroAmount() external {
        vm.prank(sender);
        vm.expectRevert("MUA:RAMAS:ZERO_AMOUNT");
        actions.redeemAndMigrateAndStake(receiver, 0);
    }

    function test_redeemAndMigrateAndStake_insufficientApproval() external {
        xmpl.mint(sender, xmplIn);

        vm.prank(sender);
        xmpl.approve(address(actions), xmplIn - 1);

        vm.prank(sender);
        vm.expectRevert("MUA:RAMAS:TRANSFER_FAIL");
        actions.redeemAndMigrateAndStake(receiver, xmplIn);
    }

    function test_redeemAndMigrateAndStake_insufficientBalance() external {
        xmpl.mint(sender, xmplIn - 1);

        vm.prank(sender);
        xmpl.approve(address(actions), xmplIn);

        vm.prank(sender);
        vm.expectRevert("MUA:RAMAS:TRANSFER_FAIL");
        actions.redeemAndMigrateAndStake(receiver, xmplIn);
    }

    function test_redeemAndMigrateAndStake_differentReceiver() external {
        mpl.mint(address(xmpl),    mplIn);
        xmpl.mint(address(sender), xmplIn);

        vm.prank(sender);
        xmpl.approve(address(actions), xmplIn);

        vm.expectEmit();
        emit Migrated(sender, address(xmpl), xmplIn, receiver, address(stsyrup), stsyrupOut);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       mplIn],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        xmplIn,          uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)]
        });

        vm.prank(sender);
        actions.redeemAndMigrateAndStake(receiver, xmplIn);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       mplIn,             uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      syrupOut,         uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        stsyrupOut,        uint256(0),      uint256(0),       uint256(0)]
        });
    }

    function test_redeemAndMigrateAndStake_sameReceiver() external {
        mpl.mint(address(xmpl),      mplIn);
        xmpl.mint(address(receiver), xmplIn);

        vm.prank(receiver);
        xmpl.approve(address(actions), xmplIn);

        vm.expectEmit();
        emit Migrated(receiver, address(xmpl), xmplIn, receiver, address(stsyrup), stsyrupOut);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       mplIn],
            xmpls:    [uint256(0),       uint256(0),        xmplIn,            uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)]
        });

        vm.prank(receiver);
        actions.redeemAndMigrateAndStake(receiver, xmplIn);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver), address(sender), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       mplIn,             uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),        uint256(0),      uint256(0),       uint256(0)],
            syrups:   [uint256(0),       uint256(0),        uint256(0),        uint256(0),      syrupOut,         uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        stsyrupOut,        uint256(0),      uint256(0),       uint256(0)]
        });
    }

    function testFuzz_redeemAndMigrateAndStake() external {
        // TODO: Fuzz: sender, receiver, amounts, exchange rates (scalars).
    }

}
