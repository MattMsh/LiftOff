const { expect } = require('chai')
import { ethers } from 'hardhat'
import { deploy } from '../scripts/web3-lib'

describe('Pool factory', () => {
    it('should deploy factory contract', async () => {
        const signers = await ethers.getSigners()
        const PoolFactory = await deploy(
            'PoolFactory',
            [
                '0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2',
                10 ^ 19,
                2 * (10 ^ 18),
                '0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db',
                '0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB',
                '0x617F2E2fD72FD9D5503197092aC168c91465E7f2',
                '0x17F6AD8Ef982297579C203069C1DbfFE4348c372'
            ],
            '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4',
            30000000000000,
        )

        const poolFactory = await ethers.getContractAt(
            'PoolFactory',
            PoolFactory.address,
        )
        // console.log(Object.keys(poolFactory));
        console.log('factory deployed at: ' + poolFactory.address)

        const pool = await poolFactory.createPoolWithToken(
            'Test',
            'TST',
            'Test token',
            'https://cf-ipfs.com/ipfs/QmTQrP6R7ieRSbKzwzLAy1i8c2U66b7LM6bSUmK1dfYc5b',
            (1000000 * 10) ^ 18
        )
        console.log(`pool created at: ${pool.address}`)
        // expect(
        //   (
        //     await poolFactory.retrieve()
        //   ).toNumber()
        // ).to.equal(0)
    })
})

/**
 *  string memory _name,
    string memory _ticker,
    string memory _description,
    string memory _image,
    uint256 _amount,
    address _feeWallet,
    address _gammaWallet,
    address _deltaWallet
 */
