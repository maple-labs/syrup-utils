import { StandardMerkleTree } from '@openzeppelin/merkle-tree'

import { Allocation } from './allocation-parser'

const types = ['uint256', 'address', 'uint256']

// Creates a Merkle tree from a list of token allocations.
export function createMerkleTree(allocations: Allocation[]): StandardMerkleTree<(string|number)[]> {
  return StandardMerkleTree.of(allocations.map(a => toLeaf(a)), types)
}

// Converts a token allocation into a Merkle tree leaf.
export function toLeaf(a: Allocation): (string | number)[] {
  if (a.id < 0) {
    throw Error('invalid allocation id')
  }

  if (a.address == '') {
    throw Error('missing allocation address')
  }

  try {
    BigInt(a.amount)
  } catch {
    throw Error('invalid allocation amount')
  }

  return [a.id, a.address, a.amount]
}
