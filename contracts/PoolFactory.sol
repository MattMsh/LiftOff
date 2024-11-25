// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PoolFormula, LiquidityPool, IERC20, Token, Ownable} from "./LiquidityPool.sol";

contract PoolFactory is Ownable {
    uint256 public contractPrice;
    address public creationFeeAddress;
    address public transactionFeeAddress;
    address public vibeAddress;
    address public vtruAirdropAddress;
    address public airDropAddress;
    address public dexRouterAddress;
    IERC20 public wvtru;

    uint256 public constant MIN_SUPPLY = 1_000_000;
    uint256 public virtualCoinBalance = 5000 ether;

    mapping(address => address[]) private userTokens;
    mapping(address => address) private pools;
    address[] private tokens;

    event PoolCreated(address indexed creator, address pool, address token);

    constructor(
        uint256 _contractPrice,
        address _creationFeeAddress,
        address _transactionFeeAddress,
        address _vibeAddress,
        address _vtruAirdropAddress,
        address _airDropAddress,
        address _wvtruAddress,
        address _dexRouterAddress
    ) Ownable(msg.sender) {
        creationFeeAddress = _creationFeeAddress;
        transactionFeeAddress = _transactionFeeAddress;
        vibeAddress = _vibeAddress;
        vtruAirdropAddress = _vtruAirdropAddress;
        airDropAddress = _airDropAddress;
        dexRouterAddress = _dexRouterAddress;
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

        LiquidityPool pool = new LiquidityPool(_name, _ticker, _uri, _amount);

        address tokenAddress = pool.getTokenAddress();
        address poolAddress = address(pool);

        pools[tokenAddress] = poolAddress;
        wvtru.transfer(creationFeeAddress, contractPrice);

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

    function getWallets() public view returns (address, address, address) {
        return (transactionFeeAddress, vibeAddress, vtruAirdropAddress);
    }

    function tokensForWvtru(uint256 wvtruAmount, uint256 tokenSupply)
        public
        view
        returns (uint256 amount, uint256 fee)
    {
        uint256 poolSupply = (tokenSupply * 98) / 100;

        amount = PoolFormula.getAmountOut((wvtruAmount * 99) / 100, virtualCoinBalance, poolSupply);

        fee = wvtruAmount / 100;
    }

    function wvtruForTokens(uint256 tokenAmount, uint256 tokenSupply)
        external
        view
        returns (uint256 amount, uint256 fee)
    {
        uint256 poolSupply = (tokenSupply * 98) / 100;
        amount = (((tokenAmount * 99) / 100) * virtualCoinBalance) / (poolSupply - tokenAmount);
        fee = ((tokenAmount / 100) * virtualCoinBalance) / (poolSupply - tokenAmount);
    }

    function setContractPrice(uint256 _price) public onlyOwner returns (bool) {
        require(_price > 0, "too low price");
        contractPrice = _price;
        return true;
    }

    function getAllTokens() public view returns (address[] memory) {
        return tokens;
    }

    function getUserTokens(address _user) public view returns (address[] memory) {
        return userTokens[_user];
    }

    function getPool(address tokenAddress) public view returns (address) {
        return pools[tokenAddress];
    }
}
