// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { console2 as console, Test } from "../../modules/forge-std/src/Test.sol";

import { SyrupDrip } from "../../contracts/SyrupDrip.sol";

import { MockERC20, MockGlobals } from "../utils/Mocks.sol";

contract SyrupDripTestBase is Test {

    event Allocated(bytes32 indexed root, uint256 deadline, uint256 maxId);
    event Claimed(uint256 indexed id, address indexed account, uint256 amount);
    event Reclaimed(address indexed account, uint256 amount);

    address governor;
    address operationalAdmin;

    MockERC20   asset;
    MockGlobals globals;

    SyrupDrip drip;

    function setUp() public virtual {
        governor         = makeAddr("governor");
        operationalAdmin = makeAddr("operationalAdmin");

        asset   = new MockERC20("SYRUP", "SYRUP", 18);
        globals = new MockGlobals(governor, operationalAdmin);

        drip = new SyrupDrip(address(asset), address(globals));
    }

}

contract SyrupDripConstructorTests is SyrupDripTestBase {

    function test_constructor() external {
        SyrupDrip drip_ = new SyrupDrip(address(asset), address(globals));

        assertEq(drip_.asset(),   address(asset));
        assertEq(drip_.globals(), address(globals));

        assertEq(drip_.root(),     bytes32(0));
        assertEq(drip_.deadline(), uint256(0));

        assertEq(asset.balanceOf(address(drip_)), 0);
    }

}

contract SyrupDripAllocateTests is SyrupDripTestBase {

    // Root of a Merkle tree generated from 4 token allocations.
    bytes32 root = 0x5a330af1653e87ea30d8bf559f0288a1268a5f87de5bb138c321b95c1fdf62b7;

    uint256 deadline = block.timestamp + 30 days;
    uint256 maxId    = 3;

    function test_allocate_notAuthorized() external {
        vm.expectRevert("SD:NOT_AUTHORIZED");
        drip.allocate(root, deadline, maxId);
    }

    function test_allocate_expiredDeadline_governor() external {
        vm.prank(governor);
        vm.expectRevert("SD:A:INVALID_DEADLINE");
        drip.allocate(root, block.timestamp - 1 seconds, maxId);
    }

    function test_allocate_expiredDeadline_operationalAdmin() external {
        vm.prank(operationalAdmin);
        vm.expectRevert("SD:A:INVALID_DEADLINE");
        drip.allocate(root, block.timestamp - 1 seconds, maxId);
    }

    function test_allocate_invalidMaxId() external {
        vm.prank(operationalAdmin);
        drip.allocate(root, deadline, maxId);

        vm.prank(operationalAdmin);
        vm.expectRevert("SD:A:INVALID_MAX_ID");
        drip.allocate(root, deadline, maxId - 1);
    }

    function test_allocate_success_governor() external {
        vm.expectEmit();
        emit Allocated(root, deadline, maxId);

        vm.prank(governor);
        drip.allocate(root, deadline, maxId);

        assertEq(drip.root(),     root);
        assertEq(drip.deadline(), deadline);
        assertEq(drip.maxId(),    maxId);
    }

    function test_allocate_success_operationalAdmin() external {
        vm.expectEmit();
        emit Allocated(root, deadline, maxId);

        vm.prank(operationalAdmin);
        drip.allocate(root, deadline, maxId);

        assertEq(drip.root(),     root);
        assertEq(drip.deadline(), deadline);
        assertEq(drip.maxId(),    maxId);
    }

}

// TODO: Add test case where we:
// 1. Allocate a new Merkle tree.
// 2. Claim a token allocation.
// 3. Allocate a new Merkle tree.
// 4. Attempt to claim an allocation from the prior merkle tree.
// 5. Ensure the claim fails.
// 6. Ensure the claim succeeds when using the new merkle tree.
contract SyrupDripClaimTests is SyrupDripTestBase {

    // Merkle tree used in tests was generated from these 6 token allocations:
    // chad      = { id: 0,    address: 0x253553366Da8546fC250F225fe3d25d0C782303b, amount: 1000000000000000000  }
    // degen     = { id: 1337, address: 0x0ac850A303169bD762a06567cAad02a8e680E7B3, amount: 15000000000000000000 }
    // habibi    = { id: 2,    address: 0xA8cc612Ecb2E853d3A882b0F9cf5357C2D892aDb, amount: 4500000000000000000  }
    // chad2     = { id: 3,    address: 0x253553366Da8546fC250F225fe3d25d0C782303b, amount: 6000000000000000000  }
    // zero      = { id: 4,    address: 0x86726BE6c9a332f10C16f9431730AFc233Db8953, amount: 0                    }
    // duplicate = { id: 2,    address: 0xE87753eB91D6A61Ea342bB9044A97764366cc7b2, amount: 1000000000000000000  }

    bytes32 root = 0xec8d1cd4e8b553e782cc92c706d9b0b78017848ed8957571ec391985f59221a0;

    uint256 deadline = block.timestamp + 30 days;
    uint256 funding  = 30e18;
    uint256 maxId    = 1337;

    uint256   id_chad      = 0;
    address   address_chad = 0x253553366Da8546fC250F225fe3d25d0C782303b;
    uint256   amount_chad  = 1e18;
    bytes32[] proof_chad;

    uint256   id_degen      = 1337;
    address   address_degen = 0x0ac850A303169bD762a06567cAad02a8e680E7B3;
    uint256   amount_degen  = 15e18;
    bytes32[] proof_degen;

    uint256   id_habibi      = 2;
    address   address_habibi = 0xA8cc612Ecb2E853d3A882b0F9cf5357C2D892aDb;
    uint256   amount_habibi  = 4.5e18;
    bytes32[] proof_habibi;

    uint256   id_chad2      = 3;
    address   address_chad2 = 0x253553366Da8546fC250F225fe3d25d0C782303b;
    uint256   amount_chad2  = 6e18;
    bytes32[] proof_chad2;

    uint256   id_zero      = 4;
    address   address_zero = 0x86726BE6c9a332f10C16f9431730AFc233Db8953;
    uint256   amount_zero  = 0;
    bytes32[] proof_zero;

    uint256   id_duplicate      = 2;
    address   address_duplicate = 0xE87753eB91D6A61Ea342bB9044A97764366cc7b2;
    uint256   amount_duplicate  = 1e18;
    bytes32[] proof_duplicate;

    function setUp() public override {
        super.setUp();

        // Merkle tree for this test case has 6 leafs, so proofs have a length of 2 or 3.
        proof_chad.push(0x9ad099f518832b5de933a522742a61226393c4f9e97ca7bd3d66a1d2113e504b);
        proof_chad.push(0xdcd601a027047bdfd645c19c9bc45c564af9171110f6a92798a837ec5a0e8ccb);

        proof_degen.push(0x9828f5c7cd91b0f3805b7ffd2419bdcdd6a90477ca0ea7b6a235c20f97a488b4);
        proof_degen.push(0xdcd601a027047bdfd645c19c9bc45c564af9171110f6a92798a837ec5a0e8ccb);

        proof_habibi.push(0x87b483be5800325b86b3ea001fdcd6f211e16cafabf21b073eaa9ddc3f667d3e);
        proof_habibi.push(0x17677931eb18b6c83af36cb94cd602cd39ad0b0242065f970ebc3771a576521d);
        proof_habibi.push(0x353ef930c6760544b8ef7eb9975e8ff35f02b2c3f193be48f583b1fcb7b8960d);

        proof_chad2.push(0x268e4a019904ec396a744c0869998a328f10d5882555bde42617ca43de7a9b02);
        proof_chad2.push(0x41e514c722940c8d945ceea6880e7081710abee3f504f98fba471c9862b4b6bd);
        proof_chad2.push(0x353ef930c6760544b8ef7eb9975e8ff35f02b2c3f193be48f583b1fcb7b8960d);

        proof_zero.push(0x62e51e715047d2ea902d88fa695f4ac295f613821843dbd3c4475d122215db3e);
        proof_zero.push(0x17677931eb18b6c83af36cb94cd602cd39ad0b0242065f970ebc3771a576521d);
        proof_zero.push(0x353ef930c6760544b8ef7eb9975e8ff35f02b2c3f193be48f583b1fcb7b8960d);

        proof_duplicate.push(0x5cba589f80b79632daa3abc01a5b91e6989c200590fbe5d88dc9f04de10e1ca8);
        proof_duplicate.push(0x41e514c722940c8d945ceea6880e7081710abee3f504f98fba471c9862b4b6bd);
        proof_duplicate.push(0x353ef930c6760544b8ef7eb9975e8ff35f02b2c3f193be48f583b1fcb7b8960d);

        // Deposit tokens in preparation of claiming.
        asset.mint(address(drip), funding);

        // Set up new token allocations.
        vm.prank(operationalAdmin);
        drip.allocate(root, deadline, maxId);
    }

    function test_claim_alreadyClaimed() external {
        drip.claim(id_habibi, address_habibi, amount_habibi, proof_habibi);

        vm.expectRevert("SD:C:ALREADY_CLAIMED");
        drip.claim(id_habibi, address_habibi, amount_habibi, proof_habibi);
    }

    function test_claim_expiredDeadline() external {
        vm.warp(deadline + 1 seconds);
        vm.expectRevert("SD:C:EXPIRED_DEADLINE");
        drip.claim(id_habibi, address_habibi, amount_habibi, proof_habibi);
    }

    function test_claim_invalidProof_id() external {
        vm.expectRevert("SD:C:INVALID_PROOF");
        drip.claim(id_habibi + 1, address_habibi, amount_habibi, proof_habibi);
    }

    function test_claim_invalidProof_account() external {
        vm.expectRevert("SD:C:INVALID_PROOF");
        drip.claim(id_habibi, address_chad, amount_habibi, proof_habibi);
    }

    function test_claim_invalidProof_amount() external {
        vm.expectRevert("SD:C:INVALID_PROOF");
        drip.claim(id_habibi, address_habibi, amount_habibi + 1, proof_habibi);
    }

    function test_claim_invalidProof_proof() external {
        proof_habibi[1] = bytes32(uint256(proof_habibi[1]) - 1);

        vm.expectRevert("SD:C:INVALID_PROOF");
        drip.claim(id_habibi, address_habibi, amount_habibi, proof_habibi);
    }

    function test_claim_transferFail() external {
        asset.burn(address(drip), funding);

        vm.expectRevert("SD:C:TRANSFER_FAIL");
        drip.claim(id_habibi, address_habibi, amount_habibi, proof_habibi);
    }

    function test_claim_success_singleClaim() external {
        assertEq(asset.balanceOf(address(drip)),           funding);
        assertEq(asset.balanceOf(address(address_habibi)), 0);

        assertEq(drip.bitmaps(0), 0);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_habibi, address_habibi, amount_habibi);

        drip.claim(id_habibi, address_habibi, amount_habibi, proof_habibi);

        assertEq(asset.balanceOf(address(drip)),           funding - amount_habibi);
        assertEq(asset.balanceOf(address(address_habibi)), amount_habibi);

        assertEq(drip.bitmaps(0), 2 ** id_habibi);
        assertEq(drip.bitmaps(1), 0);
    }

    function test_claim_success_multipleClaims() external {
        assertEq(asset.balanceOf(address(drip)),           funding);
        assertEq(asset.balanceOf(address(address_chad)),   0);
        assertEq(asset.balanceOf(address(address_habibi)), 0);

        assertEq(drip.bitmaps(0), 0);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_chad, address_chad, amount_chad);

        drip.claim(id_chad, address_chad, amount_chad, proof_chad);

        assertEq(asset.balanceOf(address(drip)),           funding - amount_chad);
        assertEq(asset.balanceOf(address(address_chad)),   amount_chad);
        assertEq(asset.balanceOf(address(address_habibi)), 0);

        assertEq(drip.bitmaps(0), 2 ** id_chad);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_habibi, address_habibi, amount_habibi);

        drip.claim(id_habibi, address_habibi, amount_habibi, proof_habibi);

        assertEq(asset.balanceOf(address(drip)),           funding - amount_chad - amount_habibi);
        assertEq(asset.balanceOf(address(address_chad)),   amount_chad);
        assertEq(asset.balanceOf(address(address_habibi)), amount_habibi);

        assertEq(drip.bitmaps(0), 2 ** id_chad + 2 ** id_habibi);
        assertEq(drip.bitmaps(1), 0);
    }

    function test_claim_success_multipleSlots() external {
        assertEq(asset.balanceOf(address(drip)),          funding);
        assertEq(asset.balanceOf(address(address_chad)),  0);
        assertEq(asset.balanceOf(address(address_degen)), 0);

        assertEq(drip.bitmaps(0), 0);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_chad, address_chad, amount_chad);

        drip.claim(id_chad, address_chad, amount_chad, proof_chad);

        assertEq(asset.balanceOf(address(drip)),          funding - amount_chad);
        assertEq(asset.balanceOf(address(address_chad)),  amount_chad);
        assertEq(asset.balanceOf(address(address_degen)), 0);

        assertEq(drip.bitmaps(0), 2 ** id_chad);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_degen, address_degen, amount_degen);

        drip.claim(id_degen, address_degen, amount_degen, proof_degen);

        assertEq(asset.balanceOf(address(drip)),          funding - amount_chad - amount_degen);
        assertEq(asset.balanceOf(address(address_chad)),  amount_chad);
        assertEq(asset.balanceOf(address(address_degen)), amount_degen);

        assertEq(drip.bitmaps(0), 2 ** id_chad);
        assertEq(drip.bitmaps(1), 0);
        assertEq(drip.bitmaps(2), 0);
        assertEq(drip.bitmaps(3), 0);
        assertEq(drip.bitmaps(4), 0);
        assertEq(drip.bitmaps(5), 2 ** (id_degen % 256));
    }

    function test_claim_success_multipleInstances() external {
        assertEq(asset.balanceOf(address(drip)),         funding);
        assertEq(asset.balanceOf(address(address_chad)), 0);

        assertEq(drip.bitmaps(0), 0);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_chad, address_chad, amount_chad);

        drip.claim(id_chad, address_chad, amount_chad, proof_chad);

        assertEq(asset.balanceOf(address(drip)),         funding - amount_chad);
        assertEq(asset.balanceOf(address(address_chad)), amount_chad);

        assertEq(drip.bitmaps(0), 2 ** id_chad);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_chad2, address_chad2, amount_chad2);

        drip.claim(id_chad2, address_chad2, amount_chad2, proof_chad2);

        assertEq(asset.balanceOf(address(drip)),         funding - amount_chad - amount_chad2);
        assertEq(asset.balanceOf(address(address_chad)), amount_chad + amount_chad2);

        assertEq(drip.bitmaps(0), 2 ** id_chad + 2 ** id_chad2);
        assertEq(drip.bitmaps(1), 0);
    }

    function test_claim_success_zeroAmount() external {
        assertEq(asset.balanceOf(address(drip)),         funding);
        assertEq(asset.balanceOf(address(address_zero)), 0);

        assertEq(drip.bitmaps(0), 0);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_zero, address_zero, amount_zero);

        drip.claim(id_zero, address_zero, amount_zero, proof_zero);

        assertEq(asset.balanceOf(address(drip)),         funding);
        assertEq(asset.balanceOf(address(address_zero)), 0);

        assertEq(drip.bitmaps(0), 2 ** id_zero);
        assertEq(drip.bitmaps(1), 0);
    }

    function test_claim_success_duplicateId() external {
        assertEq(asset.balanceOf(address(drip)),           funding);
        assertEq(asset.balanceOf(address(address_habibi)), 0);

        assertEq(drip.bitmaps(0), 0);
        assertEq(drip.bitmaps(1), 0);

        vm.expectEmit();
        emit Claimed(id_habibi, address_habibi, amount_habibi);

        drip.claim(id_habibi, address_habibi, amount_habibi, proof_habibi);

        assertEq(asset.balanceOf(address(drip)),           funding - amount_habibi);
        assertEq(asset.balanceOf(address(address_habibi)), amount_habibi);

        assertEq(drip.bitmaps(0), 2 ** id_habibi);
        assertEq(drip.bitmaps(1), 0);

        vm.expectRevert("SD:C:ALREADY_CLAIMED");
        drip.claim(id_duplicate, address_duplicate, amount_duplicate, proof_duplicate);

        assertEq(id_habibi, id_duplicate);
    }

}

contract SyrupDripReclaimTests is SyrupDripTestBase {

    address treasury = makeAddr("treasury");

    uint256 balance = 5e18;

    function setUp() public override {
        super.setUp();

        asset.mint(address(drip), balance);
    }

    function test_reclaim_notAuthorized() external {
        vm.expectRevert("SD:NOT_AUTHORIZED");
        drip.reclaim(treasury, balance);
    }

    function test_reclaim_transferFail() external {
        vm.prank(governor);
        vm.expectRevert("SD:R:TRANSFER_FAIL");
        drip.reclaim(treasury, balance + 1);
    }

    function test_reclaim_success_governor() external {
        vm.expectEmit();
        emit Reclaimed(treasury, balance);

        assertEq(asset.balanceOf(address(drip)),     balance);
        assertEq(asset.balanceOf(address(treasury)), 0);

        vm.prank(governor);
        drip.reclaim(treasury, balance);

        assertEq(asset.balanceOf(address(drip)),     0);
        assertEq(asset.balanceOf(address(treasury)), balance);
    }

    function test_reclaim_success_operationalAdmin() external {
        vm.expectEmit();
        emit Reclaimed(treasury, balance);

        assertEq(asset.balanceOf(address(drip)),     balance);
        assertEq(asset.balanceOf(address(treasury)), 0);

        vm.prank(operationalAdmin);
        drip.reclaim(treasury, balance);

        assertEq(asset.balanceOf(address(drip)),     0);
        assertEq(asset.balanceOf(address(treasury)), balance);
    }

}