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
     *  @param  receiver   Address that will receive stSYRUP.
     *  @param  mplIn      Amount of MPL to migrate.
     *  @return stsyrupOut Amount of stSYRUP received.
     */
    function migrateAndStake(address receiver, uint256 mplIn) external returns (uint256 stsyrupOut);

    /**
     *  @dev    Redeems xMPL into MPL and then migrates it to SYRUP.
     *  @param  receiver Address that will receive SYRUP.
     *  @param  xmplIn   Amount of xMPL to redeem.
     *  @return syrupOut Amount of SYRUP received.
     */
    function redeemAndMigrate(address receiver, uint256 xmplIn) external returns (uint256 syrupOut);

    /**
     *  @dev    Redeems xMPL into MPL, migrates it to SYRUP, and then stakes it.
     *  @param  receiver   Address that will receive stSYRUP.
     *  @param  xmplIn     Amount of xMPL to redeem.
     *  @return stsyrupOut Amount of stSYRUP received.
     */
    function redeemAndMigrateAndStake(address receiver, uint256 xmplIn) external returns (uint256 stsyrupOut);

}
