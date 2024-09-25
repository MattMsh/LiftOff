// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PoolFormula, LiquidityPool, IERC20, Token, Ownable} from "./LiquidityPool.sol";

contract PoolFactory is Ownable {
    uint256 public contractPrice;
    uint256 public coinsToLP;
    address public bankWallet;
    address public airDropWallet;
    address public feeWallet;
    address public gammaCurve;
    address public deltaCurve;
    address public creationFeeWallet;
    IERC20 public wvtru = IERC20(0xC0C0A38067Ba977676AB4aFD9834dB030901bE2d);

    uint128 public constant MIN_SUPPLY = 1_000_000;

    mapping(address => address[]) private userTokens;
    address[] private tokens;

    event PoolCreated(address pool, address token);

    constructor(
        uint256 _contractPrice,
        uint256 _coinsToLP,
        address _creationFeeWallet,
        address _bankWallet,
        address _airDropWallet,
        address _feeWallet,
        address _gammaWallet,
        address _deltaWallet
    ) Ownable(msg.sender) {
        require(
            _contractPrice >= _coinsToLP,
            "VTRU to LP amount must be less than contract price"
        );
        bankWallet = _bankWallet;
        airDropWallet = _airDropWallet;
        feeWallet = _feeWallet;
        gammaCurve = _gammaWallet;
        deltaCurve = _deltaWallet;
        creationFeeWallet = _creationFeeWallet;
        contractPrice = _contractPrice;
        coinsToLP = _coinsToLP;
    }

    function createPoolWithToken(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint256 _amount,
        uint256 _value
    ) public {
        uint256 allowance = wvtru.allowance(msg.sender, address(this));
        require(allowance >= _value, "check the token allowance");
        wvtru.transferFrom(msg.sender, address(this), _value);

        require(_amount >= MIN_SUPPLY * 1e18, "too few tokens to create");

        LiquidityPool pool = new LiquidityPool(
            _name,
            _ticker,
            _description,
            _image,
            _amount
        );

        address tokenAddress = pool.getTokenAddress();
        address poolAddress = address(pool);
        wvtru.transfer(creationFeeWallet, contractPrice - coinsToLP);
        wvtru.transfer(poolAddress, coinsToLP);

        userTokens[msg.sender].push(tokenAddress);
        tokens.push(tokenAddress);

        emit PoolCreated(poolAddress, tokenAddress);

        uint256 amountToBuyTokens = _value - contractPrice;
        if (amountToBuyTokens > 0) {
            wvtru.approve(poolAddress, amountToBuyTokens);
            pool.buyToken(address(this), msg.sender, amountToBuyTokens);
        }
    }

    function getWallets()
        public
        view
        returns (
            address,
            address,
            address,
            address,
            address
        )
    {
        return (bankWallet, airDropWallet, feeWallet, gammaCurve, deltaCurve);
    }

    function getOutputToken(uint256 vtruAmount, uint256 tokenSupply)
        public
        view
        returns (uint256)
    {
        return
            PoolFormula.getAmountOut(
                (vtruAmount * 99) / 100,
                coinsToLP,
                tokenSupply
            );
    }

    function getOutputVTRU(uint256 tokenAmount, uint256 tokenSupply)
        external
        view
        returns (uint256)
    {
        return
            (PoolFormula.getAmountOut(tokenAmount, tokenSupply, coinsToLP) *
                99) / 100;
    }

    function setContractPrice(uint256 _price) public onlyOwner returns (bool) {
        require(_price > 0, "too low price");
        require(_price >= coinsToLP, "contract price must be greater");
        contractPrice = _price;
        return true;
    }

    function setAmountToLP(uint256 _amount) public onlyOwner returns (bool) {
        require(_amount >= 0, "too low amount");
        require(_amount <= contractPrice, "vtru to lp amount must be less");
        coinsToLP = _amount;
        return true;
    }

    function getAllTokens() external view returns (address[] memory) {
        return tokens;
    }

    function getUserTokens(address _user)
        public
        view
        returns (address[] memory)
    {
        return userTokens[_user];
    }
}
