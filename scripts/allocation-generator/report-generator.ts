import { StandardMerkleTree } from '@openzeppelin/merkle-tree'

import { Allocation } from './allocation-parser'
import { toLeaf } from './merkle-tree'

// Generate a JSON file that defines token allocations.
export function generateReport(merkleTree: StandardMerkleTree<(string|number)[]>, allocations: Allocation[]): any {
  for (const allocation of allocations) {
    const leaf = toLeaf(allocation)
    const proof = merkleTree.getProof(leaf)
    const verified = merkleTree.verify(leaf, proof)

    if (!verified) {
      throw Error('invalid proof')
    }

    allocation.proof = proof
  }

  // TODO: Add more metadata later if needed.
  return {
    name: 'Test allocation',
    description: null,
    merkleRoot: merkleTree.root,
    maximumId: allocations.reduce((max, a) => a.id > max ? a.id : max, 0),
    deadline: null,
    allocations: allocations
  }

}
