// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    string public description;
    string public image;

    constructor(string memory _name, string memory _ticker, string memory _description, string memory _image)
        Ownable(msg.sender)
        ERC20(_name, _ticker)
    {
        description = _description;
        image = _image;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }
}
