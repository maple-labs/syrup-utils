// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISyrupDrip {

    /**************************************************************************************************************************************/
    /*** Events                                                                                                                         ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Emitted when new token allocations have been set.
     *  @param root     Root of the Merkle tree containing the new token allocations.
     *  @param deadline Deadline for claiming the allocations.
     *  @param maxId    Maximum unique identifier of all the token allocations.
     */
    event Allocated(bytes32 indexed root, uint256 deadline, uint256 maxId);

    /**
     *  @dev   Emitted when a token allocation has been claimed.
     *  @param id      Unique identifier of the token allocation.
     *  @param account Address of the account that received the tokens.
     *  @param amount  Amount of received tokens.
     */
    event Claimed(uint256 indexed id, address indexed account, uint256 amount);

    /**
     *  @dev   Emitted when tokens are reclaimed from the contract.
     *  @param account Address of the account the tokens were sent to.
     *  @param amount  Amount of reclaimed tokens.
     */
    event Reclaimed(address indexed account, uint256 amount);

    /**************************************************************************************************************************************/
    /*** State-Changing Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev   Sets new token allocations.
     *         This will cancel all of the current token allocations.
     *         Can only be called by the protocol admins.
     *  @param root     Root of the Merkle tree containing the token allocations.
     *  @param deadline Timestamp after which tokens can no longer be claimed.
     *  @param maxId    Maximum unique identifier of all the token allocations.
     */
    function allocate(bytes32 root, uint256 deadline, uint256 maxId) external;

    /**
     *  @dev   Claims a token allocation.
     *         Can only claim a token allocation once.
     *         Can only be claimed before the deadline expires.
     *         Can only be claimed if the Merkle proof is valid.
     *  @param id      Unique identifier of the token allocation.
     *  @param account Address of the token recipient.
     *  @param amount  Amount of claimed tokens.
     *  @param proof   Proof that the recipient is part of the Merkle tree of token allocations.
     */
    function claim(uint256 id, address account, uint256 amount, bytes32[] calldata proof) external;

    /**
     *  @dev   Reclaims tokens from the contract.
     *         Can only be called by the protocol admins.
     *  @param to     Address of the token recipient
     *  @param amount Amount of tokens reclaimed.
     */
    function reclaim(address to, uint256 amount) external;

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the address of the claimable ERC-20 token.
     *  @return asset Address of the ERC-20 token.
     */
    function asset() external view returns (address asset);

    /**
     *  @dev    Returns a bitmap that defines which token allocations have been claimed.
     *  @param  index  Index of the bitmap array.
     *  @return bitmap Bitmap of claimed token allocations.
     */
    function bitmaps(uint256 index) external view returns (uint256 bitmap);

    /**
     *  @dev    Returns the deadline for the current token allocations.
     *  @return deadline Timestamp before which allocations can be claimed.
     */
    function deadline() external view returns (uint256 deadline);

    /**
     *  @dev    Returns the address of the `MapleGlobals` contract.
     *  @return globals Address of the `MapleGlobals` contract.
     */
    function globals() external view returns (address globals);

    /**
     *  @dev    Returns the maximum identifier of all the current token allocations.
     *  @return maxId Maximum identifier of all the current token allocations.
     */
    function maxId() external view returns (uint256 maxId);

    /**
     *  @dev    Returns the root of the Merkle tree containing the current token allocations.
     *  @return root Root of the Merkle tree.
     */
    function root() external view returns (bytes32 root);

}
