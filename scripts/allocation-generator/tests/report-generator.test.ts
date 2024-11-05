import { createMerkleTree, toLeaf } from '../merkle-tree'
import { generateReport } from '../report-generator'

describe('generateReport tests', () => {

  it('successfully generates report using the expected format', () => {
    const allocations = [
      {
        id: 1338,
        address: '0x253553366Da8546fC250F225fe3d25d0C782303b',
        amount: '4000000000000000000',
        proof: []
      },
      {
        id: 1339,
        address: '0xA8cCCccCcB2E853D3A882B2e9dF5357c2D892adA',
        amount: '15000000000000000000',
        proof: []
      },
      {
        id: 1340,
        address: '0xb7cC612Ecb2E853D3a882B0f9cF5357C2D892ADb',
        amount: '1000000000000000001',
        proof: []
      },
      {
        id: 1341,
        address: '0x0ac850A303169bD762a06567cAad02a8e680E7B3',
        amount: '1337000000000000000',
        proof: []
      },
      {
        id: 1342,
        address: '0xd142812ecB2E853d3a882B0f9cF5357C2d892adb',
        amount: '1500000000300004000050000000',
        proof: []
      }
    ]

    const report = generateReport(
      createMerkleTree(allocations),
      allocations
    )

    expect(report).toEqual({
      name: 'allocation-2024-08',
      merkleRoot: '0xfcbe1f06eb99ffd8d9f10473340acdc7301ca858eae5d58690cb050bc696c2ed',
      maximumId: 1342,
      deadline: 1725148799,
      allocations: [
        {
          id: 1338,
          address: '0x253553366Da8546fC250F225fe3d25d0C782303b',
          amount: '4000000000000000000',
          proof: [
            '0x8c3eac853c1fa68d6e691679e7c0d4e0479b5951329b5361b110aa683a43743d',
            '0xda96c89e0a47f3797662790aa2bb6554d4f6687ca04c80c6a4da1c730416a7d7',
            '0xea91b53be74fd42bffd4950a4eec5c9804a9aad8c58c7184e29d6dd2b8a624b0'
          ]
        },
        {
          id: 1339,
          address: '0xA8cCCccCcB2E853D3A882B2e9dF5357c2D892adA',
          amount: '15000000000000000000',
          proof: [
            '0xbb4c0699b055d43a543297f6d3c060f0e84daa3a5400c88c13c7adf11b238549',
            '0x2e3f12067c64a9846d12759f632544ac7971f62af4d85cff4163fef340ef7470'
          ]
        },
        {
          id: 1340,
          address: '0xb7cC612Ecb2E853D3a882B0f9cF5357C2D892ADb',
          amount: '1000000000000000001',
          proof: [
            '0x92076059fcc1d7056067e9b305245bd4e5e5f4a56e6880f3c10f1671beaadd3a',
            '0xea91b53be74fd42bffd4950a4eec5c9804a9aad8c58c7184e29d6dd2b8a624b0'
          ]
        },
        {
          id: 1341,
          address: '0x0ac850A303169bD762a06567cAad02a8e680E7B3',
          amount: '1337000000000000000',
          proof: [
            '0xba573f01d679eb3e99a475c0c04393e3bf16ed30f9351fd3d7751c14ed554c32',
            '0x2e3f12067c64a9846d12759f632544ac7971f62af4d85cff4163fef340ef7470'
          ]
        },
        {
          id: 1342,
          address: '0xd142812ecB2E853d3a882B0f9cF5357C2d892adb',
          amount: '1500000000300004000050000000',
          proof: [
            '0x15745a8fa481fc776eb4411b7b9de92416aca0a72f7e3f0ce13392f90b787323',
            '0xda96c89e0a47f3797662790aa2bb6554d4f6687ca04c80c6a4da1c730416a7d7',
            '0xea91b53be74fd42bffd4950a4eec5c9804a9aad8c58c7184e29d6dd2b8a624b0'
          ]
        }
      ]
    })
  })

})
