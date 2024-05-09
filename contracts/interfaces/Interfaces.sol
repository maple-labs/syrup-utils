// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20Like {

    function allowance(address owner, address spender) external view returns (uint256 allowance);

    function approve(address spender, uint256 amount) external returns (bool success);

    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function transfer(address recipient, uint256 amount) external returns (bool success);

    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool success);

}

interface IPoolLike is IERC20Like {

    function asset() external view returns (address asset);

    function convertToExitAssets(uint256 shares) external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function manager() external view returns (address manager);

}

interface IPoolManagerLike {

    function poolPermissionManager() external view returns (address poolPermissionManager);

}

interface IPoolPermissionManagerLike {

    function hasPermission(address poolManager, address lender, bytes32 functionId) external view returns (bool hasPermission);

}
