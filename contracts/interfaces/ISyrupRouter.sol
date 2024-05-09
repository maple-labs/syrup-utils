// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ISyrupRouter {

    /**
     *  @dev   Optional Deposit Data for off-chain processing.
     *  @param owner       The receiver of the shares.
     *  @param amount      The amount of assets to deposit.
     *  @param depositData Optional deposit data.
     */
    event DepositData(address indexed owner, uint256 amount, bytes32 depositData);

    /**
     *  @dev    The address of the underlying asset used by the ERC4626 Vault.
     *  @return asset The address of the underlying asset.
     */
    function asset() external view returns (address asset);

    /**
     *  @dev    Mints `shares` to sender by depositing `assets` into the Vault.
     *  @param  assets      The amount of assets to deposit.
     *  @param  depositData Optional deposit data.
     *  @return shares      The amount of shares minted.
     */
    function deposit(uint256 assets, bytes32 depositData) external returns (uint256 shares);

    /**
     *  @dev    Does a ERC4626 `deposit` into a Maple Pool with a ERC-2612 `permit`.
     *  @param  amount     The amount of assets to deposit.
     *  @param  deadline   The timestamp after which the `permit` signature is no longer valid.
     *  @param  v          ECDSA signature v component.
     *  @param  r          ECDSA signature r component.
     *  @param  s          ECDSA signature s component.
     *  @param depositData Optional deposit data.
     *  @return shares     The amount of shares minted.
     */
    function depositWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s, bytes32 depositData)
        external returns (uint256 shares);

    /**
     *  @dev    The address of the ERC4626 Vault.
     *  @return pool The address of the ERC4626 Vault.
     */
    function pool() external view returns (address pool);

    /**
     *  @dev    The address of the Pool Manager.
     *  @return poolManager The address of the Pool Manager.
     */
    function poolManager() external view returns (address poolManager);

    /**
     *  @dev    The address of the Pool Permission Manager.
     *  @return poolPermissionManager The address of the Pool Permission Manager.
     */
    function poolPermissionManager() external view returns (address poolPermissionManager);

}

