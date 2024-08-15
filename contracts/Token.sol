// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    string public description;
    string public image;

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image
    ) Ownable(msg.sender) ERC20(_name, _ticker) {
        require(bytes(_description).length <= 250, "Description too long");
        // Image file size is not feasible to check directly in smart contract; using string for URI
        // require(bytes(_image).length <= 250 * 1024 * 1024, "Image file size too large");

        description = _description;
        image = _image;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
