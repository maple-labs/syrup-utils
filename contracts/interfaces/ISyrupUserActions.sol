// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISyrupUserActions {

    /**************************************************************************************************************************************/
    /*** State-Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Swaps SyrupUSDC LP token for DAI in a single transaction.
     *  @param  syrupUsdcIn The amount of SyrupUSDC to swap.
     *  @param  minDaiOut   The minimum amount of DAI to receive.
     *  @return daiOut      The amount of DAI received.
     */
    function swapToDai(uint256 syrupUsdcIn, uint256 minDaiOut) external returns (uint256 daiOut);

    /**
     *  @dev    Swaps SyrupUSDC LP token for USDC in a single transaction.
     *  @param  syrupUsdcIn The amount of SyrupUSDC to swap.
     *  @param  minUsdcOut  The minimum amount of USDC to receive.
     *  @return usdcOut     The amount of USDC received.
     */
    function swapToUsdc(uint256 syrupUsdcIn, uint256 minUsdcOut) external returns (uint256 usdcOut);

    /**
     *  @dev    Swaps SyrupUSDC LP token for USDC in a single transaction with permit.
     *  @param  syrupUsdcIn The amount of SyrupUSDC to swap.
     *  @param  minUsdcOut  The minimum amount of USDC to receive.
     *  @param  deadline    The deadline for the permit.
     *  @param  v           The v value of the permit signature.
     *  @param  r           The r value of the permit signature.
     *  @param  s           The s value of the permit signature.
     *  @return usdcOut     The amount of USDC received.
     */
    function swapToUsdcWithPermit(
        uint256 syrupUsdcIn,
        uint256 minUsdcOut,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 usdcOut);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the address of the Balancer Vault used for swapping.
     *  @return balVault The address of the Balancer Vault.
     */
    function BAL_VAULT() external view returns (address balVault);

    /**
     *  @dev    Returns the address of the DAI token.
     *  @return dai The address of the DAI token.
     */
    function DAI() external view returns (address dai);

    /**
     *  @dev    Returns the id of the Balancer Pool used for swapping.
     *  @return poolId The id of the Balancer Pool.
     */
    function POOL_ID() external view returns (bytes32 poolId);

    /**
     *  @dev    Returns the precision of the PSM contract.
     *  @return psmPrecision The precision of the PSM contract.
     */
    function PSM_PRECISION() external view returns (uint256 psmPrecision);

    /**
     *  @dev    Returns the address of the PSM contract.
     *  @return psm The address of the PSM contract.
     */
    function PSM() external view returns (address psm);

    /**
     *  @dev    Returns the address of the SyrupUSDC LP token.
     *  @return syrupUsdc The address of the SyrupUSDC LP token.
     */
    function SYRUP_USDC() external view returns (address syrupUsdc);

    /**
     *  @dev    Returns the address of the USDC token.
     *  @return usdc The address of the USDC token.
     */
    function USDC() external view returns (address usdc);

    /**
     *  @dev    Returns the address of the sDAI token.
     *  @return sDai The address of the sDAI token.
     */
    function SDAI() external view returns (address sDai);

}
