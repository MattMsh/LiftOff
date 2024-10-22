// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console, TestBase} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {PoolFactory, Token, IERC20} from "../contracts/PoolFactory.sol";

contract Token_ERC20 is MockERC20, TestBase {
    constructor(string memory name, string memory symbol, uint8 decimals) {
        initialize(name, symbol, decimals);
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }

    function unwrap(uint256 amount) external {
        _burn(msg.sender, amount);
        vm.deal(msg.sender, amount);
    }
}

contract PoolFactoryTest is Test {
    PoolFactory public factory;

    uint priceContract = 10 ether;
    uint coinsToLP = 9 ether;
    uint constant TOKEN_SUPPLY = 1_000_000 ether;

    address _creationFeeWallet = address(1);
    address _bankWallet = address(2);
    address _airDropWallet = address(3);
    address _feeWallet = address(4);
    address _gammaWallet = address(5);
    address _deltaWallet = address(6);
    Token_ERC20 public mockWvtru;

    function setUp() public {
        mockWvtru = new Token_ERC20("TKN", "TKN", 18);
        factory = new PoolFactory(
            priceContract,
            coinsToLP,
            _creationFeeWallet,
            _bankWallet,
            _airDropWallet,
            _feeWallet,
            _gammaWallet,
            _deltaWallet,
            address(mockWvtru)
        );
        factory.setContractPrice(5001 ether);
        factory.setAmountToLP(5000 ether);
    }

    function test_CalculateTokensForWVTRU() public {
        (uint amount, uint fee) = factory.tokensForWvtru(1 ether, TOKEN_SUPPLY);

        assertEq(amount, 181963607278544291141);
        assertEq(fee, 99e16);
    }

    function test_CalculateWVTRUForTokens() public {
        (uint amount, uint fee) = factory.wvtruForTokens(
            181963607278544291144,
            TOKEN_SUPPLY
        );

        assertEq(amount, 1e18);
        assertEq(fee, 99e16);
    }

    function test_createPool() public {
        mockWvtru.mint(address(this), priceContract);
        IERC20(address(mockWvtru)).approve(address(factory), priceContract);
        (address poolAddress, address tokenAddress) = factory
            .createPoolWithToken(
                "TKN",
                "TKN",
                "TKN",
                "url",
                TOKEN_SUPPLY,
                priceContract
            );

        console.log(poolAddress, tokenAddress);
    }

    function test_createPoolAndPrebuy() public {
        uint wvtruToBuy = 1 ether;
        uint amount = priceContract + wvtruToBuy;
        mockWvtru.mint(address(this), amount);
        IERC20(address(mockWvtru)).approve(address(factory), amount);
        (, address tokenAddress) = factory.createPoolWithToken(
            "TKN",
            "TKN",
            "TKN",
            "url",
            TOKEN_SUPPLY,
            amount
        );

        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        (uint amountToken, uint fee) = factory.tokensForWvtru(
            wvtruToBuy,
            TOKEN_SUPPLY
        );

        assertEq(balance, amountToken);
    }
}
