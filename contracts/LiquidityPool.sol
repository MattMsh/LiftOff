// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable, Token, IERC20} from "./Token.sol";

library PoolFormula {
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }

    function getPercentOf(uint256 _amount, uint256 _percent) internal pure returns (uint256) {
        return (_amount / 100_0000) * _percent;
    }
}

interface IPoolFactory {
    function owner() external returns (address);

    function wvtru() external returns (address);

    function creationFeeAddress() external returns (address);
    function transactionFeeAddress() external returns (address);
    function vibeAddress() external returns (address);
    function vtruAirdropAddress() external returns (address);
    function airDropAddress() external returns (address);
    function dexAddress() external returns (address);

    function virtualCoinBalance() external view returns (uint256);
}

interface wVTRU is IERC20 {
    function unwrap(uint256 amount) external;

    function wrap() external;
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    IPoolFactory public immutable factory;

    uint256 public virtualCoinBalance;
    uint256 public realCoinBalance;

    address public feeAddress;
    address public vibeAddress;

    uint256 public realTokenBalance;

    bool public initialized;
    bool private locked;
    bool private migrated;

    event Action(
        address indexed factory, address initiator, uint256 tokenAmount, uint256 vtruAmount, ActionType, string ticker
    );
    event PoolTransfered(address pair);

    modifier lock() {
        require(!locked, "locked");
        locked = true;
        _;
        locked = false;
    }

    modifier notMigrated() {
        require(!migrated, "migrated");
        _;
    }

    constructor(string memory _name, string memory _ticker, string memory _uri, uint256 _totalSupply)
        Ownable(IPoolFactory(msg.sender).owner())
    {
        factory = IPoolFactory(msg.sender);
        wvtru = wVTRU(factory.wvtru());
        initialize(_name, _ticker, _uri, _totalSupply);
    }

    function initialize(string memory _name, string memory _ticker, string memory _uri, uint256 _totalSupply) private {
        token = new Token(_name, _ticker, _uri);

        feeAddress = factory.transactionFeeAddress();
        vibeAddress = factory.vibeAddress();

        token.mint(address(this), PoolFormula.getPercentOf(_totalSupply, 98_0000));
        token.mint(factory.vtruAirdropAddress(), PoolFormula.getPercentOf(_totalSupply, 1_5789));
        token.mint(factory.airDropAddress(), PoolFormula.getPercentOf(_totalSupply, 4211));

        virtualCoinBalance = factory.virtualCoinBalance();
        _updateReserves();
    }

    function transferToNewPool() external onlyOwner lock notMigrated {
        migrated = true;

        address pair = IPancakeFactory(factory.dexAddress()).createPair(address(wvtru), address(token));

        token.burn((realTokenBalance / 75) * 100);

        token.transfer(pair, (realTokenBalance / 25) * 100);
        wvtru.transfer(pair, realCoinBalance);

        _updateReserves();

        emit PoolTransfered(pair);
    }

    function _updateReserves() private {
        realCoinBalance = wvtru.balanceOf(address(this));
        realTokenBalance = token.balanceOf(address(this));
    }

    function buyToken(address from, address to, uint256 amount) public lock notMigrated {
        require(amount > 0, "must provide wvtru to buy tokens");
        require(wvtru.allowance(from, address(this)) >= amount, "check allowance");

        (uint256 tokenAmount, uint256 fee) = _calcOutputToken(amount);

        wvtru.transferFrom(from, address(this), amount);
        token.transfer(to, tokenAmount);

        transferFees(fee);

        _updateReserves();

        emit Action(address(factory), to, tokenAmount, amount - fee, ActionType.BUY, token.symbol());
    }

    function buyToken(uint256 amount) external {
        buyToken(msg.sender, msg.sender, amount);
    }

    function sellToken(uint256 amount) external lock notMigrated {
        require(amount > 0, "must provide tokens to sell");
        require(token.allowance(msg.sender, address(this)) >= amount, "check allowance");

        (uint256 vtruAmount, uint256 fee) = _calcOutputVtru(amount);

        uint256 vtruAmountAfterFee = vtruAmount - fee;

        token.transferFrom(msg.sender, address(this), amount);
        wvtru.transfer(msg.sender, vtruAmountAfterFee);

        transferFees(fee);

        _updateReserves();

        emit Action(address(factory), msg.sender, amount, vtruAmountAfterFee, ActionType.SELL, token.symbol());
    }

    function transferFees(uint256 _amount) private returns (bool) {
        wvtru.transfer(feeAddress, PoolFormula.getPercentOf(_amount, 73_0000));
        uint256 vtruToVibe = PoolFormula.getPercentOf(_amount, 27_0000);
        wvtru.unwrap(vtruToVibe);
        if (address(this).balance < vtruToVibe) {
            vtruToVibe = address(this).balance;
        }
        (bool success,) = vibeAddress.call{value: vtruToVibe}("");
        require(success, "transfer vtru failed");
        return true;
    }

    function _calcOutputVtru(uint256 _tokenAmount) private view returns (uint256 outAmount, uint256 fee) {
        outAmount = PoolFormula.getAmountOut(_tokenAmount, getTokenBalance(), getWVtruBalance());
        fee = outAmount / 100;
    }

    function calcOutputVtru(uint256 _tokenAmount) public view notMigrated returns (uint256) {
        (uint256 outVtru, uint256 fee) = _calcOutputVtru(_tokenAmount);
        return outVtru - fee;
    }

    function _calcOutputToken(uint256 _vtruAmount) private view returns (uint256 outAmount, uint256 fee) {
        fee = _vtruAmount / 100;
        outAmount = PoolFormula.getAmountOut(_vtruAmount - fee, getWVtruBalance(), getTokenBalance());
    }

    function calcOutputToken(uint256 _vtruAmount) public view notMigrated returns (uint256) {
        (uint256 amount,) = _calcOutputToken(_vtruAmount);
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
