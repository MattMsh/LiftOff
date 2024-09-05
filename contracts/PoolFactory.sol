// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PoolFormula, LiquidityPool, Token, Ownable} from "./LiquidityPool.sol";
import {IERC20} from "./Token.sol";

struct Parameters {
    address bankWallet;
    address airDropWallet;
    address feeWallet;
    address gammaCurve;
    address deltaCurve;
}

interface PoolDeployer {
    function parameters()
        external
        view
        returns (
            address bankWallet,
            address airDropWallet,
            address feeWallet,
            address gammaCurve,
            address deltaCurve
        );
}

contract PoolFactory is Ownable, PoolDeployer {
    uint public contractPrice;
    uint public coinsToLP;
    address public immutable creationFeeWallet;
    address private constant WVTRU = 0xC0C0A38067Ba977676AB4aFD9834dB030901bE2d;
    IERC20 private immutable wvtru;
    Parameters public override parameters;
    uint public constant MIN_SUPPLY = 1_000_000 * 1e18;

    mapping(address => address[]) private userTokens;
    address[] private tokens;

    event PoolCreated(address pool, address token);
    event TransferedVTRU(address indexed to, uint amount);

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
        parameters = Parameters({
            bankWallet: _bankWallet,
            airDropWallet: _airDropWallet,
            feeWallet: _feeWallet,
            gammaCurve: _gammaWallet,
            deltaCurve: _deltaWallet
        });
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

        address tokenAddress = pool.getTokenAddress();
        address poolAddress = address(pool);

        emit PoolCreated(poolAddress, tokenAddress);
        userTokens[msg.sender].push(tokenAddress);
        tokens.push(tokenAddress);

        wvtru.transfer(creationFeeWallet, contractPrice - coinsToLP);
        wvtru.transfer(poolAddress, coinsToLP);

        uint amountToBuyTokens = _value - contractPrice;
        wvtru.approve(poolAddress, amountToBuyTokens);
        pool.buyToken(address(this), msg.sender, amountToBuyTokens);
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
