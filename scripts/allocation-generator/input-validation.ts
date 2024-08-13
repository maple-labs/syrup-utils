import { ethers, getAddress, ZeroAddress } from 'ethers'

export const DECIMALS = 18

// 1,000,000 tokens (~1% of the total supply of the new Syrup token).
export const THRESHOLD = BigInt('1000000000000000000000000')

// Parses and validates an Ethereum address.
export function parseAddress(value: string): string {
  const address = getAddress(value.toLowerCase())

  if (address == ZeroAddress) {
    throw Error('zero address')
  }

  return address
}

// Parses and validates a token amount.
export function parseAmount(value: string): string {
  const amount = BigInt(value)

  if (amount <= BigInt(0)) {
    throw Error('amount must be greater than zero')
  }

  if (amount >= THRESHOLD) {
    console.log(`WARNING: high token amount detected (${ethers.formatUnits(value, DECIMALS)})`)
  }

  return value
}
