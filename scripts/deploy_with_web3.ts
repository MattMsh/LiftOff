// This script can be used to deploy the "Storage" contract using Web3 library.
// Please make sure to compile "./contracts/1_Storage.sol" file before running this script.
// And use Right click -> "Run" from context menu of the file to run the script. Shortcut: Ctrl+Shift+S

import { deploy } from './web3-lib'
;(async () => {
    try {
        const result = await deploy(
            'PoolFactory',
            [
                '0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2',
                10 ^ 19,
                2 * (10 ^ 18),
                '0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db',
                '0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB',
                '0x617F2E2fD72FD9D5503197092aC168c91465E7f2',
                '0x17F6AD8Ef982297579C203069C1DbfFE4348c372',
                '0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678'

            ],
            '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4',
            3000000000000000000,
        )
        console.log(`address: ${result.address}`)
        console.log(result.methods)

        const pool = await result.createPoolWithToken(
            'Test',
            'TTKN',
            'Test token',
            'https://ipfs.io/ipfs/QmTQrP6R7ieRSbKzwzLAy1i8c2U66b7LM6bSUmK1dfYc5b',
            1000000 * (10 ^ 18)
        )
        console.log(`pool address: ${pool.address}`)
    } catch (e) {
        console.log(e.message)
    }
})()

/*




 string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint256 _amount,
        address _feeWallet,
        address _gammaWallet,
        address _deltaWallet



*/
