# UniswapV2周边合约学习（八）-- ExampleSwapToPrice.sol

记得朋友圈看到过一句话，如果Defi是以太坊的皇冠，那么Uniswap就是这顶皇冠中的明珠。Uniswap目前已经是V2版本，相对V1，它的功能更加全面优化，然而其合约源码却并不复杂。本文为个人学习UniswapV2源码的系列记录文章。

一、无常损失
介绍这个合约之前需要阐述另一个概念，那就是无常损失。什么是无常损失呢？这里有一篇文章讲述的比较简单明了，为什么自动做市商可能会亏钱？。该文章提到 ：

简单来说，无常损失是指在AMM中持有代币和在你自己的钱包中持有代币之间的价值差。

当AMM中的代币价格向任何方向上发生偏离时，就会发生这种情况。偏离越大，无常损失越大。

本来笔者也打算写一篇关于无常损失的学习文章，但一还没有构思好，二这篇文章写的也不错。所以在这里推荐大家先阅读这篇文章了解无常损失，但是无常损失有一个前提条件这篇文章却没有讲清楚或者讲得很明确：

单指交易对而言，没有无常损失这个概念；只有和外部价格对照并以外部价格为标准才有无常损失这个说法。

如果已经知道无常损失，那我们就往下看。

二、ExampleSwapToPrice.sol介绍
本合约的主要目的就是通过交易，让UniswapV2交易对里的资产价格和外部价格达成一致，形成套利形为，使交易的利益最大化。当然，因为这里进行了套利，所以做市商会有无常损失，不过套利形成交易对内外价格一致却是提供价格预言机的基础。

那么交易多少才能让交易对内外价格保持一致呢？根据恒定乘积算法，是可以计算出来的。这是因为有X * Y = K,X / Y = P。这里K是交易对里的恒定乘积，P就是外部价格，所以是一个简单的二元方程，是可以计算出最新的X的。再和原来的X作比较，就能计算出交易量了。

三、ExampleSwapToPrice.sol源码
pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/Babylonian.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import '../interfaces/IERC20.sol';
import '../interfaces/IUniswapV2Router01.sol';
import '../libraries/SafeMath.sol';
import '../libraries/UniswapV2Library.sol';

contract ExampleSwapToPrice {
    using SafeMath for uint256;

    IUniswapV2Router01 public immutable router;
    address public immutable factory;

    constructor(address factory_, IUniswapV2Router01 router_) public {
        factory = factory_;
        router = router_;
    }

    // computes the direction and magnitude of the profit-maximizing trade
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) pure public returns (bool aToB, uint256 amountIn) {
        aToB = reserveA.mul(truePriceTokenB) / reserveB < truePriceTokenA;

        uint256 invariant = reserveA.mul(reserveB);

        uint256 leftSide = Babylonian.sqrt(
            invariant.mul(aToB ? truePriceTokenA : truePriceTokenB).mul(1000) /
            uint256(aToB ? truePriceTokenB : truePriceTokenA).mul(997)
        );
        uint256 rightSide = (aToB ? reserveA.mul(1000) : reserveB.mul(1000)) / 997;

        // compute the amount that must be sent to move the price to the profit-maximizing price
        amountIn = leftSide.sub(rightSide);
    }

    // swaps an amount of either token such that the trade is profit-maximizing, given an external true price
    // true price is expressed in the ratio of token A to token B
    // caller must approve this contract to spend whichever token is intended to be swapped
    function swapToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 maxSpendTokenA,
        uint256 maxSpendTokenB,
        address to,
        uint256 deadline
    ) public {
        // true price is expressed as a ratio, so both values must be non-zero
        require(truePriceTokenA != 0 && truePriceTokenB != 0, "ExampleSwapToPrice: ZERO_PRICE");
        // caller can specify 0 for either if they wish to swap in only one direction, but not both
        require(maxSpendTokenA != 0 || maxSpendTokenB != 0, "ExampleSwapToPrice: ZERO_SPEND");

        bool aToB;
        uint256 amountIn;
        {
            (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
            (aToB, amountIn) = computeProfitMaximizingTrade(
                truePriceTokenA, truePriceTokenB,
                reserveA, reserveB
            );
        }

        // spend up to the allowance of the token in
        uint256 maxSpend = aToB ? maxSpendTokenA : maxSpendTokenB;
        if (amountIn > maxSpend) {
            amountIn = maxSpend;
        }

        address tokenIn = aToB ? tokenA : tokenB;
        address tokenOut = aToB ? tokenB : tokenA;
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenIn, address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        router.swapExactTokensForTokens(
            amountIn,
            0, // amountOutMin: we can skip computing this number because the math is tested
            path,
            to,
            deadline
        );
    }
}

1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
四、源码简要学习
因为合约源码我们已经学习很多次了，所以前面的pragma部分、import部分及合约定义我们都不再重复学习了，直接跳过，从合约内的状态变量开始。

using SafeMath for *uint256*;在uint256上使用SafeMath，防止上下溢出。
接下来两个状态变量定义了UniswapV2版的Router和factory合约。
构造器对上面两个状态变量进行了初始化。
computeProfitMaximizingTrade函数。核心函数，计算交易的方向和最大利益时的交易量。我们来详细看这个函数：
函数输入参数为外部价格A，外部价格B，交易对中A的数量，交易对中B的数量。注意，这里的外部价格A和B是以A和B的比值表示的，和我们平常理解的价格有所不同。例如A/B = 2/1（代表两个A才可以兑换一个B），那么这里truePriceTokenA就是2，truePriceTokenB就是1。
函数的返回值：第一个aToB返回是否卖出A，买进B，也就是交易方向为 A => B。第二个amountIn返回卖出的资产数量。
函数的第一行比较两种价格的比值来确定是交易对内是A贵了还是B贵了。假定reserveA/reserveB < truePriceTokenA/truePriceTokenB，这说明什么呢？它说明在交易对里，不需要那么多的A就可以兑换相同数量的B了（例如为reserveA/reserveB = 1.5）。那么在内部A就要贵一些，使用1.5个A就能兑换一个B（在较小的区间内近似），而外部2个A才能兑换一个B。如果A贵了就会在交易对内卖出A，反之则卖出B。但函数的第一行却没有采用这个方式计算，使用了将truePriceTokenB乘到左边去再比较（显然truePriceTokenB > 0）。为什么这么做呢？个人觉得可能是为了提高精度，因为除法为地板除，乘于某个数再除会提高计算精度（参见UniswapV2中价格为uq112x112设计）。
函数的第二行计算当前恒定乘积的值。
函数的第三行，计算价格比例达到外部价格时，此时卖出的那种资产在恒定乘积中的数量。
函数的第四行，卖出的那种资产在恒定乘积中的初始数量。
最后一行，两者的差值就是卖进的数量。但为什么结果会有1000，997之类的，是因为这里要计算手续费，所以是原输入的1000/997。
其实这里leftside为什么这么算笔者还没有研究清楚，在github上也未看到答案，只能暂时跳过去,等以后哪天突然开悟了。
这里的测试见test目录下的ExampleSwapToPrice.spec.ts。
swapToPrice函数，外部接口。主要功能利用上面的computeProfitMaximizingTrade函数计算出卖出的资产值，然后再验证是否符合用户要求。最后将符合要求后的值作为参数，调用Router合约的swapExactTokensForTokens方法进行交易。这中间还有授权，转移资产等，就不再详细介绍了。
由于个人能力有限，难免有理解错误或者不正确的地方，特别是computeProfitMaximizingTrade函数的计算暂未明白。还请大家多多留言指正。

五、结束语
本合约学习结束后，UniswapV2合约源码学习除了少数的工具库外，基本上全学习了。如果读者能认真的从《UniswapV2介绍》开始看起，直到本文结束，相信一定会对UniswapV2有深刻的认识，它的设计是非常巧妙的。当然前提是读者必须有一些Solidity语言的基础。
