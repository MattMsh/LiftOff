// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable, Token} from "./Token.sol";

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

contract LiquidityPool is Ownable {
    Token public token;

    address public immutable bankWallet; // 73% fee +  1.4211% royal
    address public immutable feeWallet; // 27% fee
    address public immutable airDropWallet; // 1.5789% royal
    address public immutable gammaWallet; // 2% bonding curve royal
    address public immutable deltaWallet; // 4% bonding curve royal

    event TokenBought(address indexed buyer, uint vtruAmount, uint tokenAmount);
    event TokenSold(address indexed seller, uint tokenAmount, uint vtruAmount);

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint _totalSupply,
        address _bankWallet,
        address _airDropWallet,
        address _feeWallet,
        address _gammaWallet,
        address _deltaWallet
    ) Ownable(msg.sender) {
        token = new Token(_name, _ticker, _description, _image);

        bankWallet = _bankWallet;
        airDropWallet = _airDropWallet;
        feeWallet = _feeWallet;
        gammaWallet = _gammaWallet;
        deltaWallet = _deltaWallet;

        token.mint(_bankWallet, getPercentOf(_totalSupply, 14211)); // 1.4211% royalty
        token.mint(_airDropWallet, getPercentOf(_totalSupply, 15789)); // 1.5789% royalty
        token.mint(_gammaWallet, getPercentOf(_totalSupply, 20000)); // 2% royalty for burn
        token.mint(_deltaWallet, getPercentOf(_totalSupply, 40000)); // 4% royalty for burn
        token.mint(address(this), getPercentOf(_totalSupply, 910000)); // 91% to LP
    }

    function getPercentOf(
        uint _amount,
        uint _percent
    ) internal pure returns (uint) {
        return (_amount / 100_0000) * _percent;
    }

    function buyToken(address buyer) public payable {
        require(msg.value > 0, "Must provide VTRU to buy tokens");

        (uint tokenAmount, uint fee) = _calcOutputToken(msg.value);

        token.transfer(buyer, tokenAmount);

        transferFees(fee);

        emit TokenBought(buyer, msg.value - fee, tokenAmount);
    }

    function buyToken() public payable {
        buyToken(msg.sender);
    }

    // Before this need to call tokens approve
    function sellToken(uint tokenAmount) external {
        require(tokenAmount > 0, "Must provide tokens to sell");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= tokenAmount, "Check the token allowance");

        (uint vtruAmount, uint fee) = _calcOutputVtru(tokenAmount);

        uint vtruAmountAfterFee = vtruAmount - fee;

        token.transferFrom(msg.sender, address(this), tokenAmount);
        payable(msg.sender).transfer(vtruAmountAfterFee);

        transferFees(fee);

        emit TokenSold(msg.sender, tokenAmount, vtruAmountAfterFee);
    }

    function transferFees(uint _amount) private returns (bool) {
        payable(bankWallet).transfer(getPercentOf(_amount, 730000));
        payable(feeWallet).transfer(getPercentOf(_amount, 270000));
        return true;
    }

    function _calcOutputVtru(
        uint _tokenAmount
    ) private view returns (uint outAmount, uint fee) {
        outAmount = PoolFormula.getAmountOut(
            _tokenAmount,
            getTokenBalance(),
            getVtruBalance()
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
            getVtruBalance() - _vtruAmount,
            getTokenBalance()
        );
    }

    function calcOutputToken(uint _vtruAmount) public view returns (uint) {
        uint fee = _vtruAmount / 100;
        return
            PoolFormula.getAmountOut(
                _vtruAmount - fee,
                getVtruBalance(),
                getTokenBalance()
            );
    }

    receive() external payable {}

    function getTokenAddress() public view returns (address) {
        return address(token);
    }

    function getVtruBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }
}
