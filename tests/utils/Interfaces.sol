// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStakedSyrupLike {
    
    function balanceOf(address account) external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

}
