// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test, Vm } from "../../modules/forge-std/src/Test.sol";

import { SyrupDrip } from "../../contracts/SyrupDrip.sol";

import { MockERC20, MockGlobals } from "../utils/Mocks.sol";

contract SyrupDripTestBase is Test {

    address governor = makeAddr("governor");
    address operationalAdmin = makeAddr("governor");

    MockERC20   asset;
    MockGlobals globals;

    SyrupDrip drip;

    function setUp() public {
        asset   = new MockERC20("USDC", "USDC", 6);
        globals = new MockGlobals(governor, operationalAdmin);

        drip = new SyrupDrip(address(asset), address(globals));

        assertEq(drip.asset(),   address(asset));
        assertEq(drip.globals(), address(globals));

        assertEq(drip.root(),     bytes32(0));
        assertEq(drip.deadline(), uint256(0));

        assertEq(asset.balanceOf(address(drip)), 0);
    }

}

contract SyrupDripAllocateTests is SyrupDripTestBase {

    event Allocated(bytes32 indexed root, uint256 deadline);

    bytes32 root = 0x5a330af1653e87ea30d8bf559f0288a1268a5f87de5bb138c321b95c1fdf62b7;

    uint256 deadline = block.timestamp + 30 days;

    function test_allocate_notAuthorized() external {
        vm.expectRevert("SD:NOT_AUTHORIZED");
        drip.allocate(root, deadline);
    }

    function test_allocate_expiredDeadline() external {
        vm.prank(governor);
        vm.expectRevert("SD:A:EXPIRED");
        drip.allocate(root, block.timestamp - 1 seconds);
    }

    function test_allocate_success_governor() external {
        vm.expectEmit();
        emit Allocated(root, deadline);

        vm.prank(governor);
        drip.allocate(root, deadline);

        assertEq(drip.root(),     root);
        assertEq(drip.deadline(), deadline);
    }

    function test_allocate_success_oa() external {
        vm.expectEmit();
        emit Allocated(root, deadline);

        vm.prank(operationalAdmin);
        drip.allocate(root, deadline);

        assertEq(drip.root(),     root);
        assertEq(drip.deadline(), deadline);
    }

}
