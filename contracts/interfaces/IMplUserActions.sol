// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMplUserActions {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    event Migrated(
        address indexed sender,
        address assetSent,
        uint256 amountSent,
        address indexed receiver,
        address assetReceived,
        uint256 amountReceived
    );

    /**************************************************************************************************************************************/
    /*** State Variables                                                                                                                ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the address of the MPL migrator contract.
     *  @return migrator Address of the migrator contract.
     */
    function migrator() external returns (address migrator);

    /**
     *  @dev    Returns the address of the MPL contract.
     *  @return mpl Address of the MPL contract.
     */
    function mpl() external returns (address mpl);

    /**
     *  @dev    Returns the address of the stSYRUP contract.
     *  @return stsyrup Address of the stSYRUP contract.
     */
    function stsyrup() external returns (address stsyrup);

    /**
     *  @dev    Returns the address of the SYRUP contract.
     *  @return syrup Address of the SYRUP contract.
     */
    function syrup() external returns (address syrup);

    /**
     *  @dev    Returns the address of the xMPL contract.
     *  @return xmpl Address of the xMPL contract.
     */
    function xmpl() external returns (address xmpl);

    /**************************************************************************************************************************************/
    /*** Functions                                                                                                                      ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Migrates MPL to SYRUP and then stakes it.
     *  @param  receiver      Address that will receive stSYRUP.
     *  @param  mplAmount     Amount of MPL to migrate.
     *  @return stsyrupAmount Amount of stSYRUP received.
     */
    function migrateAndStake(address receiver, uint256 mplAmount) external returns (uint256 stsyrupAmount);

    /**
     *  @dev    Redeems xMPL into MPL and then migrates it to SYRUP.
     *  @param  receiver    Address that will receive SYRUP.
     *  @param  xmplAmount  Amount of xMPL to redeem.
     *  @return syrupAmount Amount of SYRUP received.
     */
    function redeemAndMigrate(address receiver, uint256 xmplAmount) external returns (uint256 syrupAmount);

    /**
     *  @dev    Redeems xMPL into MPL, migrates it to SYRUP, and then stakes it.
     *  @param  receiver      Address that will receive stSYRUP.
     *  @param  xmplAmount    Amount of xMPL to redeem.
     *  @return stsyrupAmount Amount of stSYRUP received.
     */
    function redeemAndMigrateAndStake(address receiver, uint256 xmplAmount) external returns (uint256 stsyrupAmount);

}
