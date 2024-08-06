// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomToken is ERC20, Ownable {
    string public description;
    string public image;
    uint256 public tokenPrice; // Ціна за 1 токен в wei

    event TokenCreated(
        address indexed creator,
        string name,
        string ticker,
        string description,
        string image,
        uint256 amount,
        uint256 tokenPrice
    );

    event TokensPurchased(address indexed buyer, uint256 amount);

    constructor(
        address _creator,
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint256 _amount,
        uint256 _tokenPrice
    ) Ownable(_creator) ERC20(_name, _ticker) {
        require(bytes(_description).length <= 250, "Description too long");
        // Image file size is not feasible to check directly in smart contract; using string for URI
        // require(bytes(_image).length <= 250 * 1024 * 1024, "Image file size too large");
        require(_tokenPrice > 0, "Token price must be greater than zero");

        description = _description;
        image = _image;
        tokenPrice = _tokenPrice;

        _mint(_creator, _amount);

        emit TokenCreated(
            _creator,
            _name,
            _ticker,
            _description,
            _image,
            _amount,
            _tokenPrice
        );
    }

    function buyTokens() public payable {
        require(msg.value > 0, "You need to send some Ether");

        uint256 amountToBuy = msg.value / tokenPrice;

        _transfer(owner(), msg.sender, amountToBuy);
        emit TokensPurchased(msg.sender, amountToBuy);
    }
}
