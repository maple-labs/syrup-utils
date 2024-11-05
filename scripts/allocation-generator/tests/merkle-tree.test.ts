import { toLeaf } from '../merkle-tree'

const validInput = {
  id: 1,
  address: '0x253553366Da8546fC250F225fe3d25d0C782303b',
  amount: '150000000000',
  proof: [
    '0x8c3eac853c1fa68d6e691679e7c0d4e0479b5951329b5361b110aa683a43743d',
    '0xda96c89e0a47f3797662790aa2bb6554d4f6687ca04c80c6a4da1c730416a7d7',
    '0xea91b53be74fd42bffd4950a4eec5c9804a9aad8c58c7184e29d6dd2b8a624b0'
  ]
}

describe('toLeaf tests', () => {

  it('throws when invalid allocation id', () => {
    expect(() => toLeaf({ ...validInput, id: -1 })).toThrow('invalid allocation id')
  })

  it('throws when missing allocation address', () => {
    expect(() => toLeaf({ ...validInput, address: '' })).toThrow('missing allocation address')
  })

  it('throws when invalid allocation amount', () => {
    expect(() => toLeaf({ ...validInput, amount: 'asdas' })).toThrow('invalid allocation amount')
  })

  it('passes when allocation is valid', () => {
    expect(toLeaf(validInput)).toEqual([
      validInput.id,
      validInput.address,
      validInput.amount
    ])
  })

  it('ignores proof when converting allocation to leaf', () => {
    expect(toLeaf(validInput)).toEqual(toLeaf({ ...validInput, proof: [] }))
  })

})
