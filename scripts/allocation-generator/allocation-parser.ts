import { parseAddress, parseAmount } from './input-validation'
import { isClaimed } from './syrup-drip'

// A unique allocation of tokens to an address.
export type Allocation = {
  id: number       // Must be globally unique.
  address: string  // A valid, checksummed address.
  amount: string   // Uses 18 decimals of precision.
  proof: string[]  // Merkle proof used when claiming tokens.
}

// Parses CSV rows into a list of token allocations.
export async function parseAllocations(rows: string[], maxId: number): Promise<Allocation[]> {
  if (rows.length == 0) {
    throw Error('no allocations found')
  }

  let nextId = maxId > 0 ? maxId + 1 : 0

  const allocations: Allocation[] = []
  for (const row of rows) {
    const allocation = await parseAllocation(row, nextId++)

    if (allocations.map(a => a.address).includes(allocation.address)) {
      throw Error('duplicate address')
    }

    allocations.push(allocation)
  }

  return allocations
}

// Converts a CSV row and an id into an allocation object.
export async function parseAllocation(row: string, id: number): Promise<Allocation> {
    const columns = row.split(',')
    const address = parseAddress(columns[0])
    const amount = parseAmount(columns[1])

    if (await isClaimed(id)) {
      throw Error('allocation id already exists')
    }

    // TODO: Verify if `id` appears in any other previous allocation file.

    return { id, address, amount, proof: [] }
}
