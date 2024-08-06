// This script can be used to deploy the "Storage" contract using ethers.js library.
// Please make sure to compile "./contracts/1_Storage.sol" file before running this script.
// And use Right click -> "Run" from context menu of the file to run the script. Shortcut: Ctrl+Shift+S

// import { deploy } from './ethers-lib'

// (async () => {
//   try {
//     const result = await deploy('TokenFactory', [])
//     console.log(`address: ${result.address}`)
//   } catch (e) {
//     console.log(e.message)
//   }
// })()

import { deploy } from './ethers-lib'
import { ethers } from 'ethers'

(async () => {
  try {
    const result = await ethers.getContractAt('TokenFactory', '0x5FbDB2315678afecb367f032d93F642f64180aa3')
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
})()