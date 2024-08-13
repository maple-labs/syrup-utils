import * as syrupDrip from '../syrup-drip'
import { parseAllocations, parseAllocation } from '../allocation-parser'

describe('parseAllocations tests', () => {

  let isClaimedSpy: jest.SpyInstance

  beforeEach(() => {
    isClaimedSpy = jest.spyOn(syrupDrip, 'isClaimed')
    isClaimedSpy.mockResolvedValue(false)
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })

  it('throws when no rows', async () => {
    await expect(parseAllocations([], 0)).rejects.toThrow('no allocations found')
  })

  it('throws when duplicate address', async () => {
    await expect(parseAllocations(
      [
        '0x253553366Da8546fC250F225fe3d25d0C782303b,1500',
        '0x253553366Da8546fC250F225fe3d25d0C782303b,2500'
      ],
      0
    )).rejects.toThrow('duplicate address')
  })

  it('passes when rows are valid', async () => {
    const allocations = await parseAllocations(
      [
        '0x253553366Da8546fC250F225fe3d25d0C782303b,1500',
        '0xA8cccccccb2E853d3A882b2E9df5357C2D892aDa,2500'
      ],
      1337
    )

    expect(allocations).toEqual([
      {
        id: 1338,
        address: '0x253553366Da8546fC250F225fe3d25d0C782303b',
        amount: '1500',
        proof: []
      },
      {
        id: 1339,
        address: '0xA8cCCccCcB2E853D3A882B2e9dF5357c2D892adA',
        amount: '2500',
        proof: []
      }
    ])
  })

})

describe('parseAllocation tests', () => {

  let isClaimedSpy: jest.SpyInstance

  beforeEach(() => {
    isClaimedSpy = jest.spyOn(syrupDrip, 'isClaimed')
    isClaimedSpy.mockResolvedValue(false)
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })

  it('throws when row is not formatted correctly', async () => {
    await expect(parseAllocation('0x253553366Da8546fC250F225fe3d25d0C782303f;', 1337)).rejects.toThrow()
  })

  it('throws when address is invalid', async () => {
    await expect(parseAllocation('0x253553366Da8546fC250F225fe3d25d0C782303g,1500', 1337)).rejects.toThrow('invalid address')
  })

  it('throws when amount is invalid', async () => {
    await expect(parseAllocation('0x253553366Da8546fC250F225fe3d25d0C782303f,a1500', 1337)).rejects.toThrow('Cannot convert a1500 to a BigInt')
  })

  it('throws when allocation id already exists', async () => {
    isClaimedSpy.mockResolvedValue(true)

    await expect(parseAllocation('0x253553366Da8546fC250F225fe3d25d0C782303f,1500', 1337)).rejects.toThrow('allocation id already exists')
  })

  it('passes when row is valid', async () => {
    const allocation = await parseAllocation('0x253553366Da8546fC250F225fe3d25d0C782303f,1500', 1337)

    expect(allocation).toEqual({
      id: 1337,
      address: '0x253553366Da8546fC250f225fe3d25D0C782303f',
      amount: '1500',
      proof: []
    })
  })

})
