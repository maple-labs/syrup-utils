import { parseAddress, parseAmount } from '../input-validation'

describe('parseAddress tests', () => {

  it('throws when invalid address', () => {
    expect(() => parseAddress('0xdeadbeef')).toThrow('invalid address')
  })

  it('throws when zero address', () => {
    expect(() => parseAddress('0x0000000000000000000000000000000000000000')).toThrow('zero address')
  })

  it('passes when checksummed address', () => {
    const input = '0x00000000000000000000000000000000000000A1'
    const output = parseAddress(input)

    expect(output).toEqual(input)
  })

  it('passes when non-checksummed address', () => {
    const input = '0x00000000000000000000000000000000000000a1'
    const output = parseAddress(input)

    expect(output).toEqual(input.replace('a', 'A'))
  })

})

describe('parseAmount tests', () => {

  it('throws when amount is not a number', () => {
    expect(() => parseAmount('stringy')).toThrow('Cannot convert stringy to a BigInt')
  })

  it('throws when amount is not a bigint', () => {
    expect(() => parseAmount('100.15')).toThrow('Cannot convert 100.15 to a BigInt')
  })

  it('throws when amount is zero', () => {
    expect(() => parseAmount('0')).toThrow('amount must be greater than zero')
  })

  it('throws when amount is negative', () => {
    expect(() => parseAmount('-100')).toThrow('amount must be greater than zero')
  })

  it('warns when amount is over 1% of the supply', () => {
    console.log = jest.fn()

    const output = parseAmount('1000000000000000000000000')

    expect(console.log).toHaveBeenCalledWith('WARNING: high token amount detected (1000000.0)')
  })

  it('passes when amount is a valid bigint', () => {
    console.log = jest.fn()

    const output = parseAmount('99999999999999999999999')

    expect(console.log).not.toHaveBeenCalled()
  })

})
