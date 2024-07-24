// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test, Vm } from "../../modules/forge-std/src/Test.sol";

import { SyrupDrip } from "../../contracts/SyrupDrip.sol";

import { TestBase } from "./TestBase.t.sol";

contract SyrupDripTestBase is TestBase {
    
    event Allocated(bytes32 indexed root, uint256 deadline, uint256 maxId);
    event Claimed(uint256 indexed id, address indexed account, uint256 amount);
    event Reclaimed(address indexed account, uint256 amount);
    event Staked(uint256 indexed id, address indexed account, uint256 assets, uint256 shares);

    SyrupDrip drip;

    function setUp() public override {
        super.setUp();
        
        drip = new SyrupDrip(address(syrup), address(globals), address(stsyrup));
    }

}

contract AllocateIntegrationTests is SyrupDripTestBase {

    // Root of a Merkle tree generated from 4 token allocations.
    bytes32 root = 0x5a330af1653e87ea30d8bf559f0288a1268a5f87de5bb138c321b95c1fdf62b7;

    uint256 deadline = block.timestamp + 30 days;
    uint256 maxId    = 3;

    function test_allocate_notAuthorized() external {
        vm.expectRevert("SD:NOT_AUTHORIZED");
        drip.allocate(root, deadline, maxId);
    }

    function test_allocate_expiredDeadline_governor() external {
        vm.prank(governor.addr);
        vm.expectRevert("SD:A:INVALID_DEADLINE");
        drip.allocate(root, block.timestamp - 1 seconds, maxId);
    }

    function test_allocate_expiredDeadline_operationalAdmin() external {
        vm.prank(operationalAdmin.addr);
        vm.expectRevert("SD:A:INVALID_DEADLINE");
        drip.allocate(root, block.timestamp - 1 seconds, maxId);
    }

    function test_allocate_invalidMaxId() external {
        vm.prank(operationalAdmin.addr);
        drip.allocate(root, deadline, maxId);

        vm.prank(operationalAdmin.addr);
        vm.expectRevert("SD:A:INVALID_MAX_ID");
        drip.allocate(root, deadline, maxId - 1);
    }

    function test_allocate_success_governor() external {
        vm.expectEmit();
        emit Allocated(root, deadline, maxId);

        vm.prank(governor.addr);
        drip.allocate(root, deadline, maxId);

        assertEq(drip.root(),     root);
        assertEq(drip.deadline(), deadline);
        assertEq(drip.maxId(),    maxId);
    }

    function test_allocate_success_operationalAdmin() external {
        vm.expectEmit();
        emit Allocated(root, deadline, maxId);

        vm.prank(operationalAdmin.addr);
        drip.allocate(root, deadline, maxId);

        assertEq(drip.root(),     root);
        assertEq(drip.deadline(), deadline);
        assertEq(drip.maxId(),    maxId);
    }

}
