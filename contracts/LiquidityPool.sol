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
}

interface IPoolFactory {
    function owner() external returns (address);

    function wvtru() external returns (address);

    function getWallets()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );
}

interface wVTRU is IERC20 {
    function unwrap(uint256 amount) external;
    function wrap() external;
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IVTROSwapPair {
    function sync() external;
}

contract LiquidityPool is Ownable {
    Token public immutable token;
    wVTRU public immutable wvtru;
    address public immutable factory;

    uint256 private virtualCoinBalance;
    uint256 private realCoinBalance;

    uint256 private realTokenBalance;

    address public immutable bankWallet; // 73% fee +  1.4211% royal
    address public immutable vibeWallet; // 27% fee

    event TokenBought(
        address indexed buyer,
        uint256 vtruAmount,
        uint256 tokenAmount
    );
    event TokenSold(
        address indexed seller,
        uint256 tokenAmount,
        uint256 vtruAmount
    );
    event PoolTransfered(address pair);

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint256 _totalSupply
    ) Ownable(IPoolFactory(msg.sender).owner()) {
        factory = msg.sender;

        token = new Token(_name, _ticker, _description, _image);
        wvtru = wVTRU(IPoolFactory(factory).wvtru());

        (
            address _bankWallet,
            address _airDropWallet,
            address _feeWallet,
            address _gammaCurve,
            address _deltaCurve
        ) = IPoolFactory(factory).getWallets();

        bankWallet = _bankWallet;
        vibeWallet = _feeWallet;

        realCoinBalance = wvtru.balanceOf(address(this));
        virtualCoinBalance = 5000 ether; // ~1084$

        token.mint(_bankWallet, getPercentOf(_totalSupply, 1_4211)); // 1.4211% royalty
        token.mint(_airDropWallet, getPercentOf(_totalSupply, 1_5789)); // 1.5789% royalty
        token.mint(_gammaCurve, getPercentOf(_totalSupply, 2_0000)); // 2% royalty for burn
        token.mint(_deltaCurve, getPercentOf(_totalSupply, 4_0000)); // 4% royalty for burn
        
        realTokenBalance = getPercentOf(_totalSupply, 91_0000);
        token.mint(address(this), realTokenBalance); // 91% to LP
    }

    function transferToNewPool() external onlyOwner {
        address pair = IPancakeFactory(
            0x12a3E5Da7F742789F7e8d3E95Cc5E62277dC3372
        ).createPair(address(wvtru), address(token));

        token.burn((token.balanceOf(address(this)) / 75) * 100);
        token.transfer(pair, getTokenBalance());
        wvtru.transfer(pair, getWVtruBalance());

        IVTROSwapPair(pair).sync();

        emit PoolTransfered(pair);
    }

    function getPercentOf(uint256 _amount, uint256 _percent)
        internal
        pure
        returns (uint256)
    {
        return (_amount / 100_0000) * _percent;
    }

    function buyToken(
        address from,
        address to,
        uint256 amount
    ) public {
        require(amount > 0, "must provide wvtru to buy tokens");
        require(
            wvtru.allowance(from, address(this)) >= amount,
            "check allowance"
        );

        (uint256 tokenAmount, uint256 fee) = _calcOutputToken(amount);

        wvtru.transferFrom(from, address(this), amount);
        token.transfer(to, tokenAmount);

        transferFees(fee);

        emit TokenBought(to, amount - fee, tokenAmount);
    }

    function buyToken(uint256 amount) external {
        buyToken(msg.sender, msg.sender, amount);
    }

    function sellToken(uint256 amount) external {
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

        emit TokenSold(msg.sender, amount, vtruAmountAfterFee);
    }

    function transferFees(uint256 _amount) private returns (bool) {
        wvtru.transfer(bankWallet, getPercentOf(_amount, 73_0000));
        uint256 vtruToVibe = getPercentOf(_amount, 27_0000);
        wvtru.unwrap(vtruToVibe);
        if (address(this).balance < vtruToVibe) {
            vtruToVibe = address(this).balance;
        }
        (bool success, ) = vibeWallet.call{value: vtruToVibe}("");
        require(success, "transfer vtru failed");
        return true;
    }

    function _calcOutputVtru(uint256 _tokenAmount)
        private
        view
        returns (uint256 outAmount, uint256 fee)
    {
        outAmount = PoolFormula.getAmountOut(
            _tokenAmount,
            getTokenBalance(),
            getWVtruBalance()
        );
        fee = outAmount / 100;
    }

    function calcOutputVtru(uint256 _tokenAmount)
        public
        view
        returns (uint256)
    {
        (uint256 outVtru, uint256 fee) = _calcOutputVtru(_tokenAmount);
        return outVtru - fee;
    }

    function _calcOutputToken(uint256 _vtruAmount)
        private
        view
        returns (uint256 outAmount, uint256 fee)
    {
        fee = _vtruAmount / 100;
        outAmount = PoolFormula.getAmountOut(
            _vtruAmount - fee,
            getWVtruBalance(),
            getTokenBalance()
        );
    }

    function calcOutputToken(uint256 _vtruAmount)
        public
        view
        returns (uint256)
    {
        uint256 fee = _vtruAmount / 100;
        return
            PoolFormula.getAmountOut(
                _vtruAmount - fee,
                getWVtruBalance(),
                getTokenBalance()
            );
    }

    function getTokenAddress() public view returns (address) {
        return address(token);
    }

    function getWVtruBalance() private view returns (uint256) {
        return realCoinBalance + virtualCoinBalance;
    }

    function getTokenBalance() private view returns (uint256) {
        return token.balanceOf(address(this));
    }

    receive() external payable {}
}
