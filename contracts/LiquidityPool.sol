// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract LiquidityPool is Ownable {
    Token public token;

    address public constant bankWallet = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db; // 73% fee +  1.4211% royal
    address public feeWallet; // 27% fee

    address public constant airDropWallet = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB; // 1.5789% royal
    address public gammaWallet; // 2% bonding curve royal
    address public deltaWallet; // 4% bonding curve royal

    event TokenBought(address indexed buyer, uint256 vtruAmount, uint256 tokenAmount);
    event TokenSold(address indexed seller, uint256 tokenAmount, uint256 vtruAmount);
    event FeeTransferred(address indexed from, address indexed to, uint256 amount);

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint _totalSupply, 
        address _feeWallet,
        address _gammaWallet,
        address _deltaWallet
    ) Ownable(msg.sender) {
        token = new Token(_name, _ticker, _description, _image);

        feeWallet = _feeWallet;
        gammaWallet = _gammaWallet;
        deltaWallet = _deltaWallet;

        token.mint(bankWallet, getPercentOf(_totalSupply, 14211)); // 1.4211% royalty
        token.mint(airDropWallet, getPercentOf(_totalSupply, 15789)); // 1.5789% royalty
        token.mint(gammaWallet, getPercentOf(_totalSupply, 20000)); // 2% royalty for burn
        token.mint(deltaWallet, getPercentOf(_totalSupply, 40000)); // 4% royalty for burn

        token.mint(address(this), getPercentOf(_totalSupply, 910000)); // 91% to LP
    }

    function getPercentOf(uint _amount,  uint _percent) internal pure returns (uint) {
        return _amount / 100_0000 * _percent;
    }

    function buyToken() payable external {
        require(msg.value > 0, "Must provide VTRU to buy tokens");
        
        uint fee = msg.value / 100;
        uint amountWithoutFee = msg.value - fee;
        uint256 vtruReserve = getVtruBalance() + amountWithoutFee;
        uint256 tokenReserve = getTokenBalance();

        uint256 tokenAmount = tokenReserve / (vtruReserve / amountWithoutFee);
        
        token.transfer(msg.sender, tokenAmount);

        payable(bankWallet).transfer(getPercentOf(fee, 730000));
        payable(feeWallet).transfer(getPercentOf(fee, 270000));
        
        emit TokenBought(msg.sender, amountWithoutFee, tokenAmount);
    }
    
    // Before this need to call tokens approve
    function sellToken(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Must provide tokens to sell");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= tokenAmount, "Check the token allowance");
        
        uint256 vtruReserve = getVtruBalance();
        uint256 tokenReserve = getTokenBalance() + tokenAmount;

        uint256 vtruAmount = vtruReserve / (tokenReserve / tokenAmount);
       
        uint fee = vtruAmount / 100;
        uint vtruAmountAfterFee = vtruAmount - fee;
        
        token.transferFrom(msg.sender, address(this), tokenAmount);
        payable(msg.sender).transfer(vtruAmountAfterFee);

        payable(bankWallet).transfer(getPercentOf(fee, 730000));
        payable(feeWallet).transfer(getPercentOf(fee, 270000));
        
        emit TokenSold(msg.sender, tokenAmount, vtruAmountAfterFee);
    }

    // function getOutputAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) internal pure returns (uint256) {
    //     require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        
    //     uint256 inputAmountWithFee = inputAmount * 997;
    //     uint256 numerator = inputAmountWithFee * outputReserve;
    //     uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
    //     return numerator / denominator;
    // }

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
