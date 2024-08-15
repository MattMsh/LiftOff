// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17.0;
import {LiquidityPool, Ownable} from "./LiquidityPool.sol";

contract PoolFactory is Ownable {
    uint public contractPrice;
    uint public coinsToLP;

    address public immutable gnosisWallet;
    address public immutable bankWallet;
    address public immutable airDropWallet;
    address public immutable feeWallet;
    address public immutable gammaWallet;
    address public immutable deltaWallet;

    uint public constant MIN_SUPPLY = 1_000_000;

    mapping(address => address[]) private userTokens;

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
        uint _coinsToLP,
        address _bankWallet,
        address _airDropWallet, 
        address _feeWallet,
        address _gammaWallet,
        address _deltaWallet
    ) Ownable(msg.sender) {
        require(_contractPrice >= _coinsToLP, "VTRU to LP amount must be less than contract price");
        gnosisWallet = _walletToReceiveFee;
        contractPrice = _contractPrice;
        coinsToLP = _coinsToLP;
        bankWallet = _bankWallet;
        airDropWallet = _airDropWallet;
        feeWallet = _feeWallet;
        gammaWallet = _gammaWallet;
        deltaWallet = _deltaWallet;
    }

    function createPoolWithToken(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint256 _amount
    ) public payable returns (address) {
        require(msg.value >= contractPrice, "Not enough value");
        require(_amount >= MIN_SUPPLY, "Too few tokens to create");

        LiquidityPool pool = new LiquidityPool(_name, _ticker, _description, _image, _amount, bankWallet, airDropWallet, feeWallet, gammaWallet, deltaWallet);
        userTokens[msg.sender].push(pool.getTokenAddress());

        payable(gnosisWallet).transfer(contractPrice - coinsToLP);
        payable(address(pool)).transfer(coinsToLP);

        return address(pool);
    }

    function setContractPrice(uint _price) public onlyOwner returns (bool) {
        require(_price > 0, "Too low price");
        require(_price >= coinsToLP, "Contract price must be greater than amount VTRU to LP");
        contractPrice = _price;
        return true;
    }

    function setAmountToLP(uint _amount) public onlyOwner returns (bool) {
        require(_amount >= 0, "Too low amount");
        require(_amount <= contractPrice, "VTRU to LP amount must be less than contract price");
        coinsToLP = _amount;
        return true;
    }

    function getUserTokens(
        address _user
    ) public view returns (address[] memory) {
        return userTokens[_user];
    }
}
