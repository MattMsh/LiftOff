// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "./CustomToken.sol";

contract TokenFactory {
    mapping(address => address[]) userTokens;

    function createToken(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint256 _amount,
        uint256 _tokenPrice
    ) public returns (address) {
        CustomToken newToken = new CustomToken(
            msg.sender,
            _name,
            _ticker,
            _description,
            _image,
            _amount,
            _tokenPrice
        );
        userTokens[msg.sender].push(address(newToken));
        return address(newToken);
    }

    function getUserTokens(
        address _user
    ) public view returns (address[] memory) {
        return userTokens[_user];
    }
}
