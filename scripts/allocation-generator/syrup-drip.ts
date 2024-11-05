import { ethers, Contract } from 'ethers'

type _SyrupDrip = {
  isClaimed: (key: bigint) => Promise<boolean>
  maxId: () => Promise<bigint>,
}

export type SyrupDrip = Contract & _SyrupDrip

const syrupDripAbi = [
  'function isClaimed(uint256) external view returns (bool)',
  'function maxId() external view returns (uint256)'
]

// Checks if the token allocation specified by the id has been claimed.
export async function isClaimed(id: number): Promise<boolean> {
  const syrupDrip = getSyrupDrip()

  return await syrupDrip.isClaimed(BigInt(id))
}

// Reads the current maximum allocation id from a SyrupDrip contract.
export async function readMaxId(): Promise<number> {
  const syrupDrip = getSyrupDrip()

  const maxId = await syrupDrip.maxId()

  return Number(maxId)
}

function getSyrupDrip(): SyrupDrip {
  return new ethers.Contract(
    process.env.SYRUP_DRIP!,
    new ethers.Interface(syrupDripAbi),
    new ethers.JsonRpcProvider(process.env.ETH_RPC_URL!)
  ) as SyrupDrip
}
