// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PoolFormula, LiquidityPool} from "./LiquidityPool.sol";
import {IERC20, Token, Ownable} from "./Token.sol";

contract PoolFactory is Ownable {
    uint public contractPrice;
    uint public coinsToLP;
    address bankWallet;
    address airDropWallet;
    address feeWallet;
    address gammaCurve;
    address deltaCurve;
    address public immutable creationFeeWallet;
    address public constant WVTRU = 0xC0C0A38067Ba977676AB4aFD9834dB030901bE2d;
    IERC20 private immutable wvtru;
    uint public constant MIN_SUPPLY = 1_000_000 * 1e18;

    mapping(address => address[]) private userTokens;
    address[] private tokens;

    event PoolCreated(address pool, address token);

    constructor(
        address _creationFeeWallet,
        uint _contractPrice,
        uint _coinsToLP,
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
        wvtru = IERC20(WVTRU);
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
        uint _amount,
        uint _value
    ) public {
        uint256 allowance = wvtru.allowance(msg.sender, address(this));
        require(allowance >= _value, "Check the token allowance");
        wvtru.transferFrom(msg.sender, address(this), _value);

        require(_amount >= MIN_SUPPLY, "Too few tokens to create");

        LiquidityPool pool = new LiquidityPool(
            _name,
            _ticker,
            _description,
            _image,
            _amount
        );

        address tokenAddress = address(pool.token());
        address poolAddress = address(pool);
        wvtru.transfer(creationFeeWallet, contractPrice - coinsToLP);
        wvtru.transfer(poolAddress, coinsToLP);

        userTokens[msg.sender].push(tokenAddress);
        tokens.push(tokenAddress);

        emit PoolCreated(poolAddress, tokenAddress);

        uint amountToBuyTokens = _value - contractPrice;
        wvtru.approve(poolAddress, amountToBuyTokens);
        pool.buyToken(address(this), msg.sender, amountToBuyTokens);
    }

    function getWallets()
        public
        view
        returns (address, address, address, address, address)
    {
        return (bankWallet, airDropWallet, feeWallet, gammaCurve, deltaCurve);
    }

    function getOutputToken(
        uint vtruAmount,
        uint tokenSupply
    ) public view returns (uint) {
        return
            PoolFormula.getAmountOut(
                (vtruAmount * 99) / 100,
                coinsToLP,
                tokenSupply
            );
    }

    function getOutputVTRU(
        uint tokenAmount,
        uint tokenSupply
    ) external view returns (uint) {
        return
            (PoolFormula.getAmountOut(tokenAmount, tokenSupply, coinsToLP) *
                99) / 100;
    }

    function setContractPrice(uint _price) public onlyOwner returns (bool) {
        require(_price > 0, "Too low price");
        require(
            _price >= coinsToLP,
            "Contract price must be greater than amount VTRU to LP"
        );
        contractPrice = _price;
        return true;
    }

    function setAmountToLP(uint _amount) public onlyOwner returns (bool) {
        require(_amount >= 0, "Too low amount");
        require(
            _amount <= contractPrice,
            "VTRU to LP amount must be less than contract price"
        );
        coinsToLP = _amount;
        return true;
    }

    function getAllTokens() external view returns (address[] memory) {
        return tokens;
    }

    function getUserTokens(
        address _user
    ) public view returns (address[] memory) {
        return userTokens[_user];
    }
}
