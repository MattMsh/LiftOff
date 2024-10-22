// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console, TestBase} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import {PoolFactory, Token, IERC20, LiquidityPool} from "../contracts/PoolFactory.sol";

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

    uint priceContract = 1 ether;

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
            _creationFeeWallet,
            _bankWallet,
            _airDropWallet,
            _feeWallet,
            _gammaWallet,
            _deltaWallet,
            address(mockWvtru)
        );
    }

    function test_CalculateTokensForWVTRU() public view {
        (uint amount, ) = factory.tokensForWvtru(1 ether, TOKEN_SUPPLY);

        assertEq(amount, 180144331422378369082);
    }

    function test_CalculateWVTRUForTokens() public view {
        (uint amount, ) = factory.wvtruForTokens(
            181963607278544291144,
            TOKEN_SUPPLY
        );

        assertEq(amount, 0.99 ether);
    }

    function test_CreatePool() public {
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

        assertTrue(poolAddress != address(0));
        assertTrue(tokenAddress != address(0));
    }

    function test_CreatePoolAndPrebuy() public {
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
        (uint amountToken, ) = factory.tokensForWvtru(wvtruToBuy, TOKEN_SUPPLY);

        assertEq(balance, amountToken);
    }

    function test_BuyToken() public {
        uint amountToBuy = 1 ether;
        uint amount = priceContract;
        mockWvtru.mint(address(this), amount + amountToBuy);
        IERC20(address(mockWvtru)).approve(address(factory), amount);
        (address poolAddress, address tokenAddress) = factory
            .createPoolWithToken(
                "TKN",
                "TKN",
                "TKN",
                "url",
                TOKEN_SUPPLY,
                amount
            );

        LiquidityPool pool = LiquidityPool(payable(poolAddress));
        Token token = Token(tokenAddress);

        IERC20(address(mockWvtru)).approve(address(poolAddress), amountToBuy);

        pool.buyToken(amountToBuy);
        uint balance = token.balanceOf(address(this));

        (uint expectedBalance, ) = factory.tokensForWvtru(
            amountToBuy,
            TOKEN_SUPPLY
        );

        assertEq(balance, expectedBalance);
    }

    function test_SellToken() public {
        uint amountToBuy = 1 ether;
        uint amount = priceContract;
        mockWvtru.mint(address(this), amount + amountToBuy);
        IERC20(address(mockWvtru)).approve(address(factory), amount);
        (address poolAddress, address tokenAddress) = factory
            .createPoolWithToken(
                "TKN",
                "TKN",
                "TKN",
                "url",
                TOKEN_SUPPLY,
                amount
            );

        LiquidityPool pool = LiquidityPool(payable(poolAddress));
        Token token = Token(tokenAddress);

        IERC20(address(mockWvtru)).approve(address(poolAddress), amountToBuy);

        pool.buyToken(amountToBuy);

        uint tokenBalance = token.balanceOf(address(this));
        IERC20(tokenAddress).approve(address(poolAddress), tokenBalance);
        pool.sellToken(tokenBalance);

        (uint expectedBalance, ) = factory.wvtruForTokens(
            tokenBalance,
            TOKEN_SUPPLY
        );

        uint balance = IERC20(address(mockWvtru)).balanceOf(address(this));

        assertApproxEqAbs(balance, expectedBalance, 1);
    }

    function test_InitialMarketCap() public {
        mockWvtru.mint(address(this), priceContract);
        IERC20(address(mockWvtru)).approve(address(factory), priceContract);
        (address poolAddress, ) = factory.createPoolWithToken(
            "TKN",
            "TKN",
            "TKN",
            "url",
            TOKEN_SUPPLY,
            priceContract
        );

        LiquidityPool pool = LiquidityPool(payable(poolAddress));

        uint priceForToken = pool.calcOutputVtru(1 ether);

        uint totalPriceForTokens = (pool.realTokenBalance() / 1 ether) *
            priceForToken;

        console.log(totalPriceForTokens);
        assertApproxEqAbs(totalPriceForTokens, 5000 ether, 100 ether);
    }

    function test_MarketCapAfterBuy() public {
        uint amountToBuy = 100 ether;
        uint amount = priceContract;
        mockWvtru.mint(address(this), amount + amountToBuy);
        IERC20(address(mockWvtru)).approve(address(factory), amount);
        (address poolAddress, ) = factory.createPoolWithToken(
            "TKN",
            "TKN",
            "TKN",
            "url",
            TOKEN_SUPPLY,
            amount
        );

        LiquidityPool pool = LiquidityPool(payable(poolAddress));

        IERC20(address(mockWvtru)).approve(address(poolAddress), amountToBuy);

        pool.buyToken(amountToBuy);

        uint priceForToken = pool.calcOutputVtru(1 ether);

        uint totalPriceForTokens = (pool.realTokenBalance() / 1 ether) *
            priceForToken;

        assertApproxEqAbs(totalPriceForTokens, 5000 ether, 100 ether);
    }
}
