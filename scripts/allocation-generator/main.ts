import * as fs from 'fs'
import * as path from 'path'
import dotenv from 'dotenv'

import { parseAllocations } from './allocation-parser'
import { createMerkleTree } from './merkle-tree'
import { generateReport } from './report-generator'
import { readMaxId } from './syrup-drip'

// Load environment variables from .env file
dotenv.config()

// Generates a JSON token allocation report from an input CSV.
async function main(): Promise<void> {
  if (process.env.ETH_RPC_URL! == null) {
    throw Error("'ETH_RPC_URL' not set")
  }

  if (process.env.SYRUP_DRIP! == null) {
    throw Error("'SYRUP_DRIP' address not set")
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

  console.log(`Max ID: ${maxId}`)

  console.log("Reading CSV file...")

  const allocations = await parseAllocations(rows, maxId)

  console.log("Creating Merkle tree...")

  const merkleTree = createMerkleTree(allocations)

  console.log("Generating JSON...")

  const report = generateReport(merkleTree, allocations)

  // Write the report into a JSON file.
  fs.writeFileSync(
    path.format({ ...path.parse(csvPath), base: '', ext: '.json' }),
    JSON.stringify(report, null, 2) + '\n'
  )
}

main()
