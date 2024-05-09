// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { MockERC20 as BaseMockERC20 } from "../../modules/erc20/contracts/test/mocks/MockERC20.sol";

contract MockERC20 is BaseMockERC20 {

    constructor(string memory name_, string memory symbol_, uint8 decimals_) BaseMockERC20(name_, symbol_, decimals_) {}

    bool _approveReverts;
    bool _transferReverts;
    bool _transferFromReverts;

    function __setApproveReverts(bool reverts_) external {
        _approveReverts = reverts_;
    }

    function __setTransferReverts(bool reverts_) external {
        _transferReverts = reverts_;
    }

    function __setTransferFromReverts(bool reverts_) external {
        _transferFromReverts = reverts_;
    }

    function approve(address spender_, uint256 amount_) public override returns (bool success_) {
        if (_approveReverts) require(false);

        success_ = super.approve(spender_, amount_);
    }

    function transfer(address to_, uint256 amount_) public override returns (bool success_) {
        if (_transferReverts) require(false);

        success_ = super.transfer(to_, amount_);
    }

    function transferFrom(address from_, address to_, uint256 amount_) public override returns (bool success_) {
        if (_transferFromReverts) require(false);

        success_ = super.transferFrom(from_, to_, amount_);
    }

    function permit(address owner_, address spender_, uint amount_, uint deadline_, uint8 v_, bytes32 r_, bytes32 s_) public override {
        super.permit(owner_, spender_, amount_, deadline_, v_, r_, s_);
    }

}

contract MockPool is MockERC20 {

    address _asset;
    address _manager;

    uint256 _conversionRate;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address asset_,
        address manager_
    )
        MockERC20(name_, symbol_, decimals_)
    {
        _asset   = asset_;
        _manager = manager_;
    }

    function __setConversionRate(uint256 conversionRate_) external {
        _conversionRate = conversionRate_;
    }

    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_) {
        MockERC20(_asset).transferFrom(msg.sender, address(this), assets_);
        _mint(receiver_, shares_ = assets_);
    }

    function asset() external view returns (address asset_) {
        asset_ = _asset;
    }

    function conversionRate() external view returns (uint256 conversionRate_) {
        conversionRate_ = _conversionRate;
    }

    function manager() external view returns (address manager_) {
        manager_ = _manager;
    }

    function convertToExitAssets(uint256) external view returns (uint256 assets_) {
        assets_ = _conversionRate;
    }

}

contract MockPoolManager {

    address _poolPermissionManager;

    constructor(address poolPermissionManager_) {
        _poolPermissionManager = poolPermissionManager_;
    }

    function poolPermissionManager() external view returns (address poolPermissionManager_) {
        poolPermissionManager_ = _poolPermissionManager;
    }

}

contract MockPoolPermissionManager {

    bool _hasPermission = true;

    function __setHasPermission(bool hasPermission_) external {
        _hasPermission = hasPermission_;
    }

    function hasPermission(address, address, bytes32) external view returns (bool hasPermission_) {
        hasPermission_ = _hasPermission;
    }

}