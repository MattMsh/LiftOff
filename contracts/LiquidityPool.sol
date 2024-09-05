// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable, Token, IERC20} from "./Token.sol";
import {PoolDeployer, PoolFactory} from "./PoolFactory.sol";
import "./wVTRU/wVTRU.sol";

library PoolFormula {
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        uint numerator = amountIn * reserveOut;
        uint denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }
}

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IVTROSwapPair {
    function sync() external;
}

contract LiquidityPool is Ownable {
    Token public immutable token;
    wVTRU public immutable wvtru;
    address public immutable factory;

    address public immutable bankWallet; // 73% fee +  1.4211% royal
    address public immutable vibeWallet; // 27% fee

    event TokenBought(address indexed buyer, uint vtruAmount, uint tokenAmount);
    event TokenSold(address indexed seller, uint tokenAmount, uint vtruAmount);

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint _totalSupply
    ) Ownable(PoolFactory(msg.sender).owner()) {
        factory = msg.sender;

        token = new Token(_name, _ticker, _description, _image);
        wvtru = wVTRU(PoolFactory(factory).WVTRU());

        (
            _bankWallet,
            _airDropWallet,
            _feeWallet,
            _gammaCurve,
            _deltaCurve
        ) = PoolDeployer(factory).parameters();

        bankWallet = _bankWallet;
        vibeWallet = _feeWallet;

        token.mint(_bankWallet, getPercentOf(_totalSupply, 1_4211)); // 1.4211% royalty
        token.mint(_airDropWallet, getPercentOf(_totalSupply, 1_5789)); // 1.5789% royalty
        token.mint(_gammaCurve, getPercentOf(_totalSupply, 2_0000)); // 2% royalty for burn
        token.mint(_deltaCurve, getPercentOf(_totalSupply, 4_0000)); // 4% royalty for burn
        token.mint(address(this), getPercentOf(_totalSupply, 91_0000)); // 91% to LP
    }

    function transferToNewPool() external onlyOwner {
        token.burn(token.balanceOf(address(this)) / 2);
        address pair = IPancakeFactory(
            0x12a3E5Da7F742789F7e8d3E95Cc5E62277dC3372
        ).createPair(address(wvtru), address(token));

        token.transfer(pair, token.balanceOf(getTokenBalance()));
        wvtru.transfer(pair, wvtru.balanceOf(getWVtruBalance()));

        IVTROSwapPair(pair).sync();
    }

    function getPercentOf(
        uint _amount,
        uint _percent
    ) internal pure returns (uint) {
        return (_amount / 100_0000) * _percent;
    }

    function buyToken(address from, address to, uint amount) internal {
        require(amount > 0, "must provide wvtru to buy tokens");
        require(
            wvtru.allowance(from, address(this)) >= amount,
            "check allowance"
        );

        (uint tokenAmount, uint fee) = _calcOutputToken(amount);

        wvtru.transferFrom(from, address(this), amount);
        token.transfer(to, tokenAmount);

        transferFees(fee);

        emit TokenBought(to, amount - fee, tokenAmount);
    }

    function buyToken(uint amount) external {
        buyToken(msg.sender, msg.sender, amount);
    }

    function sellToken(uint amount) external {
        require(amount > 0, "must provide tokens to sell");
        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "check allowance"
        );

        (uint vtruAmount, uint fee) = _calcOutputVtru(amount);

        uint vtruAmountAfterFee = vtruAmount - fee;

        token.transferFrom(msg.sender, address(this), amount);
        wvtru.transfer(msg.sender, vtruAmountAfterFee);

        transferFees(fee);

        emit TokenSold(msg.sender, amount, vtruAmountAfterFee);
    }

    function transferFees(uint _amount) private returns (bool) {
        wvtru.transfer(bankWallet, getPercentOf(_amount, 73_0000));
        uint vtruToVibe = getPercentOf(_amount, 27_0000);
        wvtru.unwrap(vtruToVibe);
        (bool success, ) = feeWallet.call{value: vtruToVibe}("");
        require(success, "transfer vtru failed");
        return true;
    }

    function _calcOutputVtru(
        uint _tokenAmount
    ) private view returns (uint outAmount, uint fee) {
        outAmount = PoolFormula.getAmountOut(
            _tokenAmount,
            getTokenBalance(),
            getWVtruBalance()
        );
        fee = outAmount / 100;
    }

    function calcOutputVtru(uint _tokenAmount) public view returns (uint) {
        (uint outVtru, uint fee) = _calcOutputVtru(_tokenAmount);
        return outVtru - fee;
    }

    function _calcOutputToken(
        uint _vtruAmount
    ) private view returns (uint outAmount, uint fee) {
        fee = _vtruAmount / 100;
        outAmount = PoolFormula.getAmountOut(
            _vtruAmount - fee,
            getWVtruBalance(),
            getTokenBalance()
        );
    }

    function calcOutputToken(uint _vtruAmount) public view returns (uint) {
        uint fee = _vtruAmount / 100;
        return
            PoolFormula.getAmountOut(
                _vtruAmount - fee,
                getWVtruBalance(),
                getTokenBalance()
            );
    }

    function getTokenAddress() internal view returns (address) {
        return address(token);
    }

    function getWVtruBalance() private view returns (uint) {
        return wvtru.balanceOf(address(this));
    }

    function getTokenBalance() private view returns (uint) {
        return token.balanceOf(address(this));
    }
}
