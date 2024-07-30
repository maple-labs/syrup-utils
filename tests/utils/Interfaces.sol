// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStakedSyrupLike {
    
    function balanceOf(address account) external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

}

interface ISyrupUserActionsLike {

    function swapToDai(uint256 syrupUsdcIn_, uint256 minDaiOut_, address receiver_) external returns (uint256 daiOut_);

}

interface IPSMLike {

    function file(bytes32 what, uint256 data) external;

    function tout() external returns (uint256 tout_);

}
