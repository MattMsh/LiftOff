// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PoolFormula, LiquidityPool, Token, Ownable} from "./LiquidityPool.sol";
import {ERC20} from "./Token.sol";

contract PoolFactory is Ownable {
    uint public contractPrice;
    uint public coinsToLP;

    address public immutable gnosisWallet;
    address public immutable bankWallet;
    address public immutable airDropWallet;
    address public immutable feeWallet;
    address public immutable gammaWallet;
    address public immutable deltaWallet;

    uint public constant MIN_SUPPLY = 1_000_000 * 1e18;

    mapping(address => address[]) private userTokens;

    event PoolCreated(address pool);
    event TransferedVTRU(address indexed to, uint amount);

    constructor(
        address _walletToReceiveFee,
        uint _contractPrice,
        uint _coinsToLP,
        address _bankWallet,
        address _airDropWallet,
        address _feeWallet,
        address _gammaWallet,
        address _deltaWallet
    ) Ownable(msg.sender) {
        require(
            _contractPrice >= _coinsToLP,
            "VTRU to LP amount must be less than contract price"
        );
        gnosisWallet = _walletToReceiveFee;
        contractPrice = _contractPrice;
        coinsToLP = _coinsToLP;
        bankWallet = _bankWallet;
        airDropWallet = _airDropWallet;
        feeWallet = _feeWallet;
        gammaWallet = _gammaWallet;
        deltaWallet = _deltaWallet;
    }

    function createPoolWithToken(
        string memory _name,
        string memory _ticker,
        string memory _description,
        string memory _image,
        uint _amount
    ) public payable {
        require(msg.value >= contractPrice, "Not enough value");
        require(_amount >= MIN_SUPPLY, "Too few tokens to create");

        LiquidityPool pool = new LiquidityPool(
            _name,
            _ticker,
            _description,
            _image,
            _amount,
            bankWallet,
            airDropWallet,
            feeWallet,
            gammaWallet,
            deltaWallet
        );

        emit PoolCreated(address(pool));

        userTokens[msg.sender].push(pool.getTokenAddress());

        // (bool sentToGnosis, ) = payable(gnosisWallet).call{
        //     value: contractPrice - coinsToLP
        // }("");
        // emit TransferedVTRU(gnosisWallet, contractPrice - coinsToLP);
        // (bool sentToPool, ) = payable(address(pool)).call{value: coinsToLP}("");
        // emit TransferedVTRU(gnosisWallet, coinsToLP);
        // require(sentToGnosis, "Failed send to Gnosis 1");
        // require(sentToPool, "Failed send to pool");

        // uint amountToBuyTokens = msg.value - contractPrice;
        // if (amountToBuyTokens > 10000) {
        //     pool.buyToken{value: amountToBuyTokens}(msg.sender);
        // }
    }

    function getOutputToken(
        uint vtruAmount,
        uint tokenSupply
    ) public view returns (uint) {
        return
            PoolFormula.getAmountOut(
                (vtruAmount * 99) / 100,
                coinsToLP,
                tokenSupply
            );
    }

    function getOutputVTRU(
        uint tokenAmount,
        uint tokenSupply
    ) external view returns (uint) {
        return
            (PoolFormula.getAmountOut(tokenAmount, tokenSupply, coinsToLP) *
                99) / 100;
    }

    function setContractPrice(uint _price) public onlyOwner returns (bool) {
        require(_price > 0, "Too low price");
        require(
            _price >= coinsToLP,
            "Contract price must be greater than amount VTRU to LP"
        );
        contractPrice = _price;
        return true;
    }

    function setAmountToLP(uint _amount) public onlyOwner returns (bool) {
        require(_amount >= 0, "Too low amount");
        require(
            _amount <= contractPrice,
            "VTRU to LP amount must be less than contract price"
        );
        coinsToLP = _amount;
        return true;
    }

    function getUserTokens(
        address _user
    ) public view returns (address[] memory) {
        return userTokens[_user];
    }
}
