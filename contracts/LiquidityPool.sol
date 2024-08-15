// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17.0;

import { Ownable, Token } from "./Token.sol";

contract LiquidityPool is Ownable {
    Token public token;

    address public immutable bankWallet; // 73% fee +  1.4211% royal
    address public immutable feeWallet; // 27% fee
    address public immutable airDropWallet; // 1.5789% royal
    address public immutable gammaWallet; // 2% bonding curve royal
    address public immutable deltaWallet; // 4% bonding curve royal

    event TokenBought(address indexed buyer, uint256 vtruAmount, uint256 tokenAmount);
    event TokenSold(address indexed seller, uint256 tokenAmount, uint256 vtruAmount);

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

    function getPercentOf(uint _amount,  uint _percent) internal pure returns (uint) {
        return _amount / 100_0000 * _percent;
    }

    function buyToken() external payable {
        require(msg.value > 0, "Must provide VTRU to buy tokens");
        
        uint fee = msg.value / 100;
        uint vtruAmountWithoutFee = msg.value - fee;

        uint256 tokenAmount = calcOutputToken(vtruAmountWithoutFee);
        
        token.transfer(msg.sender, tokenAmount);

        transferFees(fee);
        
        emit TokenBought(msg.sender, vtruAmountWithoutFee, tokenAmount);
    }
    
    // Before this need to call tokens approve
    function sellToken(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Must provide tokens to sell");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= tokenAmount, "Check the token allowance");

        uint256 vtruAmount = calcOutputVtru(tokenAmount);
       
        uint fee = vtruAmount / 100;
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

    function calcOutputVtru(uint _tokenAmount) view public returns (uint) {
        uint vtruBalance = getVtruBalance();
        uint tokenReserve = getTokenBalance() + _tokenAmount;

        return ((vtruBalance / (tokenReserve / _tokenAmount)) * 99) / 100;
    }

    function calcOutputToken(uint _vtruAmount) view public returns (uint) {
        uint tokenBalance = getTokenBalance();
        uint vtruReserve = getVtruBalance() + _vtruAmount;

        return ((tokenBalance / (vtruReserve / _vtruAmount)) * 99) / 100;
    }

    receive() external payable { }

    function getTokenAddress() public view returns (address) {
        return address(token);
    }
    
    function getVtruBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
