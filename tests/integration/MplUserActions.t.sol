// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test, Vm } from "../../modules/forge-std/src/Test.sol";

import { IERC20 }                            from "../../modules/erc20/contracts/interfaces/IERC20.sol";
import { IMapleGlobals }                     from "../../modules/globals-v2/contracts/interfaces/IMapleGlobals.sol";
import { IMigrator }                         from "../../modules/mpl-migration/contracts/interfaces/IMigrator.sol";
import { IRevenueDistributionToken as IRDT } from "../../modules/xmpl/contracts/interfaces/IxMPL.sol";

import { MapleGlobals }          from "../../modules/globals-v2/contracts/MapleGlobals.sol";
import { NonTransparentProxy }   from "../../modules/globals-v2/modules/non-transparent-proxy/contracts/NonTransparentProxy.sol";
import { Migrator }              from "../../modules/mpl-migration/contracts/Migrator.sol";
import { xMPL as RDT }           from "../../modules/xmpl/contracts/xMPL.sol";

import { MplUserActions } from "../../contracts/MplUserActions.sol";

contract MplUserActionsTestBase is Test {

    event Migrated(
        address indexed sender,
        address assetSent,
        uint256 amountSent,
        address indexed receiver,
        address assetReceived,
        uint256 amountReceived
    );

    uint256 precision = 1e30;
    uint256 scalar    = 100;

    // NOTE: Syrup initializer always mints the same amount (ignoring scalar).
    uint256 mplSupply   = 10_000_000e18;
    uint256 syrupSupply = mplSupply;

    // NOTE: xMPL and stSYRUP do not have any additional accrued value.
    uint256 mplIn      = 1_000e18;
    uint256 xmplIn     = mplIn;
    uint256 syrupOut   = mplIn * scalar;
    uint256 stsyrupOut = syrupOut;

    Vm.Wallet governor = vm.createWallet("governor");
    Vm.Wallet receiver = vm.createWallet("receiver");
    Vm.Wallet sender   = vm.createWallet("sender");

    IERC20        mpl;
    IERC20        syrup;
    IMapleGlobals globals;
    IMigrator     migrator;
    IRDT          stsyrup;
    IRDT          xmpl;

    MplUserActions actions;

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20312565);

        // NOTE: Mints 10_000_000 MPL to the deployer (`msg.sender`).
        vm.prank(sender.addr);
        mpl = IERC20(deployCode("./out/MapleToken.sol/MapleToken.json", abi.encode("Maple Token", "MPL", address(1))));

        globals = IMapleGlobals(address(new NonTransparentProxy(governor.addr, address(new MapleGlobals()))));

        // NOTE: Would be replaced with precomputed address of the migrator.
        migrator = IMigrator(address(0x1337));

        // NOTE: There are two contracts named `MapleToken`, one of them is in the root and the other is in the `contracts` directory.
        syrup = IERC20(deployCode("./out/MapleTokenProxy.sol/MapleTokenProxy.json", abi.encode(
            address(globals),
            deployCode("./out/contracts/MapleToken.sol/MapleToken.json"),
            deployCode("./out/MapleTokenInitializer.sol/MapleTokenInitializer.json"),
            address(migrator)
        )));

        stsyrup = new RDT("Staked Syrup", "stSYRUP", governor.addr, address(syrup), precision);
        xmpl    = new RDT("xMPL", "xMPL", governor.addr, address(mpl), precision);

        // NOTE: Sets migrator code onto precomputed address.
        address transplant = address(new Migrator(address(globals), address(mpl), address(syrup), scalar));
        vm.etch(address(migrator), transplant.code);

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

    function signPermit(
        address asset,
        Vm.Wallet memory owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    )
        internal returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 digest = keccak256(abi.encodePacked(
            '\x19\x01',
            IERC20(asset).DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                IERC20(asset).PERMIT_TYPEHASH(),
                owner.addr,
                spender,
                value,
                nonce,
                deadline
            ))
        ));

        ( v, r, s ) = vm.sign(owner, digest);
    }

}

contract MigrateAndStakeTests is MplUserActionsTestBase {

}

contract MigrateAndStakeWithPermitTests is MplUserActionsTestBase {

}

contract RedeemAndMigrateTests is MplUserActionsTestBase {

}

contract RedeemAndMigrateWithPermitTests is MplUserActionsTestBase {

}

contract RedeemAndMigrateAndStakeTests is MplUserActionsTestBase {

    function test_integration_redeemAndMigrateAndStake_zeroAmount() external {
        vm.prank(sender.addr);
        vm.expectRevert("MUA:RAMAS:ZERO_AMOUNT");
        actions.redeemAndMigrateAndStake(receiver.addr, 0);
    }

    function test_integration_redeemAndMigrateAndStake_insufficientApproval() external {
        vm.prank(sender.addr);
        mpl.approve(address(xmpl), mplIn);

        vm.prank(sender.addr);
        xmpl.deposit(mplIn, sender.addr);

        vm.prank(sender.addr);
        xmpl.approve(address(actions), xmplIn - 1);

        vm.prank(sender.addr);
        vm.expectRevert("MUA:RAMAS:TRANSFER_FAIL");
        actions.redeemAndMigrateAndStake(receiver.addr, xmplIn);
    }

    function test_integration_redeemAndMigrateAndStake_insufficientBalance() external {
        vm.prank(sender.addr);
        mpl.approve(address(xmpl), mplIn);

        vm.prank(sender.addr);
        xmpl.deposit(mplIn, sender.addr);

        vm.prank(sender.addr);
        xmpl.approve(address(actions), xmplIn + 1);

        vm.prank(sender.addr);
        vm.expectRevert("MUA:RAMAS:TRANSFER_FAIL");
        actions.redeemAndMigrateAndStake(receiver.addr, xmplIn + 1);
    }

    function test_integration_redeemAndMigrateAndStake_migratorInactive() external {
        vm.prank(sender.addr);
        mpl.approve(address(xmpl), mplIn);

        vm.prank(sender.addr);
        xmpl.deposit(mplIn, sender.addr);

        vm.prank(sender.addr);
        xmpl.approve(address(actions), xmplIn);

        vm.prank(sender.addr);
        vm.expectRevert("M:M:INACTIVE");
        actions.redeemAndMigrateAndStake(receiver.addr, xmplIn);
    }

    function test_integration_redeemAndMigrateAndStake_success() external {
        vm.prank(governor.addr);
        migrator.setActive(true);

        vm.prank(sender.addr);
        mpl.approve(address(xmpl), mplIn);

        vm.prank(sender.addr);
        xmpl.deposit(mplIn, sender.addr);

        vm.prank(sender.addr);
        xmpl.approve(address(actions), xmplIn);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver.addr), address(sender.addr), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       uint256(0),        uint256(0),             mplSupply - mplIn,    uint256(0),       mplIn],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),             xmplIn,               uint256(0),       uint256(0)],
            syrups:   [uint256(0),       syrupSupply,       uint256(0),             uint256(0),           uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),             uint256(0),           uint256(0),       uint256(0)]
        });

        vm.expectEmit();
        emit Migrated(sender.addr, address(xmpl), xmplIn, receiver.addr, address(stsyrup), stsyrupOut);

        vm.prank(sender.addr);
        uint256 amount = actions.redeemAndMigrateAndStake(receiver.addr, xmplIn);

        uint256 syrupDiff = syrupSupply - syrupOut;
        uint256 mplDiff   = mplSupply - mplIn;

        assertEq(amount, stsyrupOut);
        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver.addr), address(sender.addr), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       mplIn,             uint256(0),             mplDiff,              uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),             uint256(0),           uint256(0),       uint256(0)],
            syrups:   [uint256(0),       syrupDiff,         uint256(0),             uint256(0),           syrupOut,         uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        stsyrupOut,             uint256(0),           uint256(0),       uint256(0)]
        });
    }

}

contract RedeemAndMigrateAndStakeWithPermitTests is MplUserActionsTestBase {

    function test_integration_redeemAndMigrateAndStakeWithPermit_expiredDeadline() external {
        ( uint8 v, bytes32 r, bytes32 s ) = signPermit(address(xmpl), sender, address(actions), xmplIn, 0, block.timestamp);

        vm.warp(block.timestamp + 1 seconds);
        vm.prank(sender.addr);
        vm.expectRevert("ERC20:P:EXPIRED");
        actions.redeemAndMigrateAndStakeWithPermit(receiver.addr, xmplIn, block.timestamp - 1 seconds, v, r, s);
    }

    function test_integration_redeemAndMigrateAndStakeWithPermit_malleable() external {
        ( uint8 v, bytes32 r, bytes32 s ) = signPermit(address(xmpl), sender, address(actions), xmplIn, 0, block.timestamp);

        v *= 2;

        vm.prank(sender.addr);
        vm.expectRevert("ERC20:P:MALLEABLE");
        actions.redeemAndMigrateAndStakeWithPermit(receiver.addr, xmplIn, block.timestamp, v, r, s);
    }

    function test_integration_redeemAndMigrateAndStakeWithPermit_invalidSignature() external {
        ( uint8 v, bytes32 r, bytes32 s ) = signPermit(address(xmpl), sender, address(actions), xmplIn, 0, block.timestamp);

        s <<= 1;

        vm.prank(sender.addr);
        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        actions.redeemAndMigrateAndStakeWithPermit(receiver.addr, xmplIn, block.timestamp, v, r, s);
    }

    function test_integration_redeemAndMigrateAndStakeWithPermit_zeroAmount() external {
        ( uint8 v, bytes32 r, bytes32 s ) = signPermit(address(xmpl), sender, address(actions), 0, 0, block.timestamp);

        vm.prank(sender.addr);
        vm.expectRevert("MUA:RAMAS:ZERO_AMOUNT");
        actions.redeemAndMigrateAndStakeWithPermit(receiver.addr, 0, block.timestamp, v, r, s);
    }

    function test_integration_redeemAndMigrateAndStakeWithPermit_insufficientBalance() external {
        vm.prank(sender.addr);
        mpl.approve(address(xmpl), mplIn);

        vm.prank(sender.addr);
        xmpl.deposit(mplIn, sender.addr);

        ( uint8 v, bytes32 r, bytes32 s ) = signPermit(address(xmpl), sender, address(actions), xmplIn + 1, 0, block.timestamp);

        vm.prank(sender.addr);
        vm.expectRevert("MUA:RAMAS:TRANSFER_FAIL");
        actions.redeemAndMigrateAndStakeWithPermit(receiver.addr, xmplIn + 1, block.timestamp, v, r, s);
    }

    function test_integration_redeemAndMigrateAndStakeWithPermit_migratorInactive() external {
        vm.prank(sender.addr);
        mpl.approve(address(xmpl), mplIn);

        vm.prank(sender.addr);
        xmpl.deposit(mplIn, sender.addr);

        ( uint8 v, bytes32 r, bytes32 s ) = signPermit(address(xmpl), sender, address(actions), xmplIn, 0, block.timestamp);

        vm.prank(sender.addr);
        vm.expectRevert("M:M:INACTIVE");
        actions.redeemAndMigrateAndStakeWithPermit(receiver.addr, xmplIn, block.timestamp, v, r, s);
    }

    function test_integration_redeemAndMigrateAndStakeWithPermit_success() external {
        vm.prank(governor.addr);
        migrator.setActive(true);

        vm.prank(sender.addr);
        mpl.approve(address(xmpl), mplIn);

        vm.prank(sender.addr);
        xmpl.deposit(mplIn, sender.addr);

        ( uint8 v, bytes32 r, bytes32 s ) = signPermit(address(xmpl), sender, address(actions), xmplIn, 0, block.timestamp);

        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver.addr), address(sender.addr), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       uint256(0),        uint256(0),             mplSupply - mplIn,    uint256(0),       mplIn],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),             xmplIn,               uint256(0),       uint256(0)],
            syrups:   [uint256(0),       syrupSupply,       uint256(0),             uint256(0),           uint256(0),       uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        uint256(0),             uint256(0),           uint256(0),       uint256(0)]
        });

        vm.expectEmit();
        emit Migrated(sender.addr, address(xmpl), xmplIn, receiver.addr, address(stsyrup), stsyrupOut);

        vm.prank(sender.addr);
        uint256 amount = actions.redeemAndMigrateAndStakeWithPermit(receiver.addr, xmplIn, block.timestamp, v, r, s);

        uint256 syrupDiff = syrupSupply - syrupOut;
        uint256 mplDiff   = mplSupply - mplIn;

        assertEq(amount, stsyrupOut);
        assertBalances({
            accounts: [address(actions), address(migrator), address(receiver.addr), address(sender.addr), address(stsyrup), address(xmpl)],
            mpls:     [uint256(0),       mplIn,             uint256(0),             mplDiff,              uint256(0),       uint256(0)],
            xmpls:    [uint256(0),       uint256(0),        uint256(0),             uint256(0),           uint256(0),       uint256(0)],
            syrups:   [uint256(0),       syrupDiff,         uint256(0),             uint256(0),           syrupOut,         uint256(0)],
            stsyrups: [uint256(0),       uint256(0),        stsyrupOut,             uint256(0),           uint256(0),       uint256(0)]
        });
    }

}
