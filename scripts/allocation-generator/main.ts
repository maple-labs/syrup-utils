import * as fs from 'fs'
import * as path from 'path'

import { parseAllocations } from './allocation-parser'
import { createMerkleTree } from './merkle-tree'
import { generateReport } from './report-generator'
import { readMaxId } from './syrup-drip'

// Generates a JSON token allocation report from an input CSV.
async function main(): Promise<void> {
  if (process.env.ETH_RPC_URL! == null) {
    throw Error('\'ETH_RPC_URL\' not set')
  }

  if (process.env.SYRUP_DRIP! == null) {
    throw Error('\'SYRUP_DRIP\' address not set')
  }

  const csvPath = process.argv[2]

  if (!fs.existsSync(csvPath)) {
    throw Error(`File not found: ${csvPath}`)
  }

  // Read the input CSV file.
  const data = await fs.promises.readFile(csvPath, 'utf-8')
  const rows = data.trim().split('\n')

  // Generate the token allocation report.
  const maxId = await readMaxId()
  const allocations = await parseAllocations(rows, maxId)
  const merkleTree = createMerkleTree(allocations)
  const report = generateReport(merkleTree, allocations)

  // Write the report into a JSON file.
  fs.writeFileSync(
    path.format({ ...path.parse(csvPath), base: '', ext: '.json' }),
    JSON.stringify(report, null, 2) + '\n'
  )
}

main()
