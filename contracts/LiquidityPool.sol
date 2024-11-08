// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable, Token, IERC20} from "./Token.sol";

library PoolFormula {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }

    function getPercentOf(
        uint256 _amount,
        uint256 _percent
    ) internal pure returns (uint256) {
        return (_amount / 100_0000) * _percent;
    }
}

interface IPoolFactory {
    function owner() external returns (address);

    function wvtru() external returns (address);

    function getWallets() external view returns (address, address, address);

    function virtualCoinBalance() external view returns (uint256);
}

interface wVTRU is IERC20 {
    function unwrap(uint256 amount) external;

    function wrap() external;
}

interface IPancakeFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IVTROSwapPair {
    function sync() external;
}

contract LiquidityPool is Ownable {
    enum ActionType {
        BUY,
        SELL
    }
    Token public token;
    wVTRU public immutable wvtru;
    address public immutable factory;

    uint256 public virtualCoinBalance;
    uint256 public realCoinBalance;

    uint256 public realTokenBalance;

    address public bankWallet; // 73% fee +  1.4211% royal
    address public vibeWallet; // 27% fee

    bool public initialized;
    bool private locked;

    event Action(address initiator, uint256 tokenAmount,
        uint256 vtruAmount, ActionType, address indexed factory);
    event PoolTransfered(address pair);

    modifier lock() {
        require(!locked, "locked");
        locked = true;
        _;
        locked = false;
    }

    constructor() Ownable(IPoolFactory(msg.sender).owner()) {
        factory = msg.sender;
        wvtru = wVTRU(IPoolFactory(factory).wvtru());
    }

    function initialize(
        string calldata _name,
        string calldata _ticker,
        string calldata _uri,
        uint256 _totalSupply
    ) external lock returns (address, address) {
        require(!initialized, "already initialized");
        initialized = true;

        token = new Token(_name, _ticker, _uri);
        (
            address _bankWallet,
            address _airDropWallet,
            address _feeWallet
        ) = IPoolFactory(factory).getWallets();
        bankWallet = _bankWallet;
        vibeWallet = _feeWallet;

        token.mint(_bankWallet, PoolFormula.getPercentOf(_totalSupply, 4211)); // 0.4211% royalty
        token.mint(
            _airDropWallet,
            PoolFormula.getPercentOf(_totalSupply, 1_5789)
        ); // 1.5789% royalty
        token.mint(
            address(this),
            PoolFormula.getPercentOf(_totalSupply, 98_0000)
        ); // 98% to LP

        virtualCoinBalance = IPoolFactory(factory).virtualCoinBalance(); // ~1084$
        _updateReserves();

        return (address(token), address(this));
    }

    function transferToNewPool() external onlyOwner lock {
        address pair = IPancakeFactory(
            0x12a3E5Da7F742789F7e8d3E95Cc5E62277dC3372
        ).createPair(address(wvtru), address(token));

        token.burn((realTokenBalance / 75) * 100);

        token.transfer(pair, (realTokenBalance / 25) * 100);
        wvtru.transfer(pair, realCoinBalance);

        _updateReserves();

        IVTROSwapPair(pair).sync();

        emit PoolTransfered(pair);
    }

    function _updateReserves() private {
        realCoinBalance = wvtru.balanceOf(address(this));
        realTokenBalance = token.balanceOf(address(this));
    }

    function buyToken(address from, address to, uint256 amount) public lock {
        require(amount > 0, "must provide wvtru to buy tokens");
        require(
            wvtru.allowance(from, address(this)) >= amount,
            "check allowance"
        );

        (uint256 tokenAmount, uint256 fee) = _calcOutputToken(amount);

        wvtru.transferFrom(from, address(this), amount);
        token.transfer(to, tokenAmount);

        transferFees(fee);

        _updateReserves();

        emit Action(to, tokenAmount, amount - fee, ActionType.BUY, factory);
    }

    function buyToken(uint256 amount) external {
        buyToken(msg.sender, msg.sender, amount);
    }

    function sellToken(uint256 amount) external lock {
        require(amount > 0, "must provide tokens to sell");
        require(
            token.allowance(msg.sender, address(this)) >= amount,
            "check allowance"
        );

        (uint256 vtruAmount, uint256 fee) = _calcOutputVtru(amount);

        uint256 vtruAmountAfterFee = vtruAmount - fee;

        token.transferFrom(msg.sender, address(this), amount);
        wvtru.transfer(msg.sender, vtruAmountAfterFee);

        transferFees(fee);

        _updateReserves();

        emit Action(msg.sender, amount, vtruAmountAfterFee, ActionType.SELL, factory);
    }

    function transferFees(uint256 _amount) private returns (bool) {
        wvtru.transfer(bankWallet, PoolFormula.getPercentOf(_amount, 73_0000));
        uint256 vtruToVibe = PoolFormula.getPercentOf(_amount, 27_0000);
        wvtru.unwrap(vtruToVibe);
        if (address(this).balance < vtruToVibe) {
            vtruToVibe = address(this).balance;
        }
        (bool success, ) = vibeWallet.call{value: vtruToVibe}("");
        require(success, "transfer vtru failed");
        return true;
    }

    function _calcOutputVtru(
        uint256 _tokenAmount
    ) private view returns (uint256 outAmount, uint256 fee) {
        outAmount = PoolFormula.getAmountOut(
            _tokenAmount,
            getTokenBalance(),
            getWVtruBalance()
        );
        fee = outAmount / 100;
    }

    function calcOutputVtru(
        uint256 _tokenAmount
    ) public view returns (uint256) {
        (uint256 outVtru, uint256 fee) = _calcOutputVtru(_tokenAmount);
        return outVtru - fee;
    }

    function _calcOutputToken(
        uint256 _vtruAmount
    ) private view returns (uint256 outAmount, uint256 fee) {
        fee = _vtruAmount / 100;
        outAmount = PoolFormula.getAmountOut(
            _vtruAmount - fee,
            getWVtruBalance(),
            getTokenBalance()
        );
    }

    function calcOutputToken(
        uint256 _vtruAmount
    ) public view returns (uint256) {
        (uint amount, ) = _calcOutputToken(_vtruAmount);
        return amount;
    }

    function getTokenAddress() public view returns (address) {
        return address(token);
    }

    function getWVtruBalance() private view returns (uint256) {
        return realCoinBalance + virtualCoinBalance;
    }

    function getTokenBalance() private view returns (uint256) {
        return realTokenBalance;
    }

    receive() external payable {}
}
