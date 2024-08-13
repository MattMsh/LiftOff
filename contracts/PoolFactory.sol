// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "hardhat/console.sol";

import "./LiquidityPool.sol";

contract PoolFactory is Ownable {
    uint contractPrice;
    uint coinsToLP;

    address public immutable gnosisWallet1;

    mapping(address => address[]) userTokens;

    event TokenCreated(
        address indexed creator,
        string name,
        string ticker,
        string description,
        string image,
        uint256 amount
    );

    constructor(
        address _walletToReceiveFee,
        uint _contractPrice,
        uint _coinsToLP
    ) Ownable(msg.sender) {
        gnosisWallet1 = _walletToReceiveFee;
        contractPrice = _contractPrice;
        coinsToLP = _coinsToLP;
    }

    function createPoolWithToken(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint256 _amount,
        address _feeWallet,
        address _gammaWallet,
        address _deltaWallet
    ) public payable returns (address) {
        require(msg.value >= getContractPrice(), "Not enough value");
        require(_amount >= 1000, "Too few tokens to create");

        LiquidityPool pool = new LiquidityPool(_name, _ticker, _description, _image, _amount, _feeWallet, _gammaWallet, _deltaWallet);
        userTokens[msg.sender].push(pool.getTokenAddress());

        payable(gnosisWallet1).transfer(contractPrice);
        payable(address(pool)).transfer(coinsToLP);

        return address(pool);
    }

    function getContractPrice() public view returns(uint) {
        return contractPrice + coinsToLP;
    }

    function setContractPrice(uint _price) public onlyOwner returns (bool) {
        require(_price > 0, "Too low price");
        contractPrice = _price;
        return true;
    }

    function setAmountToLP(uint _amount) public onlyOwner returns (bool) {
        require(_amount >= 0, "Too low amount");
        coinsToLP = _amount;
        return true;
    }

    function getUserTokens(
        address _user
    ) public view returns (address[] memory) {
        return userTokens[_user];
    }
}
