// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PoolFormula, LiquidityPool, IERC20, Token, Ownable} from "./LiquidityPool.sol";

contract PoolFactory is Ownable {
    uint256 public contractPrice;
    address public bankWallet;
    address public airDropWallet;
    address public feeWallet;
    address public gammaCurve;
    address public deltaCurve;
    address public creationFeeWallet;
    IERC20 public wvtru;

    uint256 public constant MIN_SUPPLY = 1_000_000;
    uint256 public virtualCoinBalance = 5000 ether;

    mapping(address => address[]) private userTokens;
    mapping(address => address) private pools;
    address[] private tokens;

    event PoolCreated(address indexed creator, address pool, address token);

    constructor(
        uint256 _contractPrice,
        address _creationFeeWallet,
        address _bankWallet,
        address _airDropWallet,
        address _feeWallet,
        address _gammaWallet,
        address _deltaWallet,
        address _wvtruAddress
    ) Ownable(msg.sender) {
        bankWallet = _bankWallet;
        airDropWallet = _airDropWallet;
        feeWallet = _feeWallet;
        gammaCurve = _gammaWallet;
        deltaCurve = _deltaWallet;
        creationFeeWallet = _creationFeeWallet;
        contractPrice = _contractPrice;
        wvtru = IERC20(_wvtruAddress);
    }

    function createPoolWithToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _uri,
        uint256 _amount,
        uint256 _value
    ) public returns (address, address) {
        uint256 allowance = wvtru.allowance(msg.sender, address(this));
        require(allowance >= _value, "check the token allowance");
        wvtru.transferFrom(msg.sender, address(this), _value);

        require(_amount >= MIN_SUPPLY * 1e18, "too few tokens to create");

        LiquidityPool pool = new LiquidityPool();
        (address tokenAddress, address poolAddress) = pool.initialize(
            _name,
            _ticker,
            _uri,
            _amount
        );
        pools[tokenAddress] = poolAddress;
        wvtru.transfer(creationFeeWallet, contractPrice);

        userTokens[msg.sender].push(tokenAddress);
        tokens.push(tokenAddress);

        emit PoolCreated(msg.sender, poolAddress, tokenAddress);

        uint256 amountToBuyTokens = _value - contractPrice;
        if (amountToBuyTokens > 0) {
            wvtru.approve(poolAddress, amountToBuyTokens);
            pool.buyToken(address(this), msg.sender, amountToBuyTokens);
        }

        return (poolAddress, tokenAddress);
    }

    function getWallets()
        public
        view
        returns (address, address, address, address, address)
    {
        return (bankWallet, airDropWallet, feeWallet, gammaCurve, deltaCurve);
    }

    function tokensForWvtru(
        uint256 wvtruAmount,
        uint256 tokenSupply
    ) public view returns (uint256 amount, uint256 fee) {
        amount = (wvtruAmount * 99) / 100;
        amount =
            (amount * ((tokenSupply * 91) / 100)) /
            (virtualCoinBalance + amount);
        fee = wvtruAmount / 100;
    }

    function wvtruForTokens(
        uint256 tokenAmount,
        uint256 tokenSupply
    ) external view returns (uint256 amount, uint256 fee) {
        amount =
            (tokenAmount * virtualCoinBalance) /
            (((tokenSupply * 91) / 100) - tokenAmount);
        fee = amount / 100;
        amount = (amount * 99) / 100;
    }

    function setContractPrice(uint256 _price) public onlyOwner returns (bool) {
        require(_price > 0, "too low price");
        contractPrice = _price;
        return true;
    }

    function getAllTokens() public view returns (address[] memory) {
        return tokens;
    }

    function getUserTokens(
        address _user
    ) public view returns (address[] memory) {
        return userTokens[_user];
    }

    function getPool(address tokenAddress) public view returns (address) {
        return pools[tokenAddress];
    }
}
