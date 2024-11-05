import { StandardMerkleTree } from '@openzeppelin/merkle-tree'

import { Allocation } from './allocation-parser'
import { toLeaf } from './merkle-tree'

// Generate a JSON file that defines the token allocation.
export function generateReport(merkleTree: StandardMerkleTree<(string|number)[]>, allocations: Allocation[]): any {

  // Generate proofs for each token allocation and verify them.
  for (const allocation of allocations) {
    const leaf = toLeaf(allocation)
    const proof = merkleTree.getProof(leaf)
    const verified = merkleTree.verify(leaf, proof)

    if (!verified) {
      throw Error('invalid proof')
    }

    allocation.proof = proof
  }

  // Define the deadline as the end of the current month.
  const deadline = new Date()
  deadline.setUTCMonth(deadline.getUTCMonth() + 1);
  deadline.setUTCDate(0);
  deadline.setUTCHours(23, 59, 59, 0);

  // Format the name of the allocation file.
  const year = deadline.getUTCFullYear()
  const month = (deadline.getUTCMonth() + 1).toString().padStart(2, '0')

  return {
    allocations: allocations,
    deadline: deadline.getTime() / 1000,
    maximumId: allocations.reduce((max, a) => a.id > max ? a.id : max, 0),
    merkleRoot: merkleTree.root,
    name: `allocation-${year}-${month}`,
  }

}
