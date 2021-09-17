# UniswapV2周边合约学习（九）-- ExampleCombinedSwapAddRemoveLiquidity.sol


## 一、单资产流动性供给

我们知道，Uniswap在提供流动性时必须同时按比例注入交易对中的两种资产，然后得到流动性代币。同时需要两种资产，这无形中提高了用户的门槛。如果用户只有一种（或者只关注一种）资产怎么办呢？能不能提供流动性供给？答案可以的。

在Router合约中提供了流动性管理的接口，同时也提供了资产交易的接口。那么我们可以在同一个函数里将这两个功能联合起来，先交易资产然后再提供流动性，或者先移除流动性再交易资产。

如果单资产提供流动性，先要在提供的资产中分一部分出来进行交易，得到另外一种资产，这样就有两种资产了。然后再调用Router合约的增加流动性接口注入资产提供流动性。那么分多少资产出来进行交易才能保证资产全部注入（注入时的比例和交易后交易对中的比例相同），是这个操作的核心，需要使用公式进行计算。

如果移除流动性并得到单资产，这个相对简单很多。先移除流动性得到两种资产，然后再将其中一种资产兑换成另一种即可。这样得到的资产就是提取的数量加上交易得到的数量。

可以看到，对Uniswap来讲，这里的单资产流动性供给实质还是双资产注入（其底层实现决定的），只是提前将单资产兑换成了双资产。

注：这里还有其它类型的单资产流动性供给，例如BancorV2(班科第二版)及一些类似的DEFI。他们并不需要将单资产兑换成双资产，而是在交易对中为每种资产都生成一个流动性代币，从而实现单资产注入。

## 二、ExampleCombinedSwapAddRemoveLiquidity.sol源码

本合约源码不在周边合约uniswap-v2-periphery的master分支下，而是位于swap-before-liquidity-events分支下。所在目录为examples目录。

合约源码为:
```
pragma solidity =0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/UniswapV2Library.sol";

// enables adding and removing liquidity with a single token to/from a pair
// adds liquidity via a single token of the pair, by first swapping against the pair and then adding liquidity
// removes liquidity in a single token, by removing liquidity and then immediately swapping
contract ExampleCombinedSwapAddRemoveLiquidity {
    using SafeMath for uint;

    IUniswapV2Factory public immutable factory;
    IUniswapV2Router01 public immutable router;
    IWETH public immutable weth;

    constructor(IUniswapV2Factory factory_, IUniswapV2Router01 router_, IWETH weth_) public {
        factory = factory_;
        router = router_;
        weth = weth_;
    }

    // grants unlimited approval for a token to the router unless the existing allowance is high enough
    function approveRouter(address _token, uint256 _amount) internal {
        uint256 allowance = IERC20(_token).allowance(address(this), address(router));
        if (allowance < _amount) {
            if (allowance > 0) {
                // clear the existing allowance
                TransferHelper.safeApprove(_token, address(router), 0);
            }
            TransferHelper.safeApprove(_token, address(router), uint256(-1));
        }
    }

    // returns the amount of token that should be swapped in such that ratio of reserves in the pair is equivalent
    // to the swapper's ratio of tokens
    // note this depends only on the number of tokens the caller wishes to swap and the current reserves of that token,
    // and not the current reserves of the other token
    function calculateSwapInAmount(uint reserveIn, uint userIn) public pure returns (uint) {
        return Babylonian.sqrt(reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))).sub(reserveIn.mul(1997)) / 1994;
    }

    // internal function shared by the ETH/non-ETH versions
    function _swapExactTokensAndAddLiquidity(
        address from,
        address tokenIn,
        address otherToken,
        uint amountIn,
        uint minOtherTokenIn,
        address to,
        uint deadline
    ) internal returns (uint amountTokenIn, uint amountTokenOther, uint liquidity) {
        // compute how much we should swap in to match the reserve ratio of tokenIn / otherToken of the pair
        uint swapInAmount;
        {
            (uint reserveIn,) = UniswapV2Library.getReserves(address(factory), tokenIn, otherToken);
            swapInAmount = calculateSwapInAmount(reserveIn, amountIn);
        }

        // first take possession of the full amount from the caller, unless caller is this contract
        if (from != address(this)) {
            TransferHelper.safeTransferFrom(tokenIn, from, address(this), amountIn);
        }
        // approve for the swap, and then later the add liquidity. total is amountIn
        approveRouter(tokenIn, amountIn);

        {
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = otherToken;

            amountTokenOther = router.swapExactTokensForTokens(
                swapInAmount,
                minOtherTokenIn,
                path,
                address(this),
                deadline
            )[1];
        }

        // approve the other token for the add liquidity call
        approveRouter(otherToken, amountTokenOther);
        amountTokenIn = amountIn.sub(swapInAmount);

        // no need to check that we transferred everything because minimums == total balance of this contract
        (,,liquidity) = router.addLiquidity(
            tokenIn,
            otherToken,
        // desired amountA, amountB
            amountTokenIn,
            amountTokenOther,
        // amountTokenIn and amountTokenOther should match the ratio of reserves of tokenIn to otherToken
        // thus we do not need to constrain the minimums here
            0,
            0,
            to,
            deadline
        );
    }

    // computes the exact amount of tokens that should be swapped before adding liquidity for a given token
    // does the swap and then adds liquidity
    // minOtherToken should be set to the minimum intermediate amount of token1 that should be received to prevent
    // excessive slippage or front running
    // liquidity provider shares are minted to the 'to' address
    function swapExactTokensAndAddLiquidity(
        address tokenIn,
        address otherToken,
        uint amountIn,
        uint minOtherTokenIn,
        address to,
        uint deadline
    ) external returns (uint amountTokenIn, uint amountTokenOther, uint liquidity) {
        return _swapExactTokensAndAddLiquidity(
            msg.sender, tokenIn, otherToken, amountIn, minOtherTokenIn, to, deadline
        );
    }

    // similar to the above method but handles converting ETH to WETH
    function swapExactETHAndAddLiquidity(
        address token,
        uint minTokenIn,
        address to,
        uint deadline
    ) external payable returns (uint amountETHIn, uint amountTokenIn, uint liquidity) {
        weth.deposit{value: msg.value}();
        return _swapExactTokensAndAddLiquidity(
            address(this), address(weth), token, msg.value, minTokenIn, to, deadline
        );
    }

    // internal function shared by the ETH/non-ETH versions
    function _removeLiquidityAndSwap(
        address from,
        address undesiredToken,
        address desiredToken,
        uint liquidity,
        uint minDesiredTokenOut,
        address to,
        uint deadline
    ) internal returns (uint amountDesiredTokenOut) {
        address pair = UniswapV2Library.pairFor(address(factory), undesiredToken, desiredToken);
        // take possession of liquidity and give access to the router
        TransferHelper.safeTransferFrom(pair, from, address(this), liquidity);
        approveRouter(pair, liquidity);

        (uint amountInToSwap, uint amountOutToTransfer) = router.removeLiquidity(
            undesiredToken,
            desiredToken,
            liquidity,
        // amount minimums are applied in the swap
            0,
            0,
        // contract must receive both tokens because we want to swap the undesired token
            address(this),
            deadline
        );

        // send the amount in that we received in the burn
        approveRouter(undesiredToken, amountInToSwap);

        address[] memory path = new address[](2);
        path[0] = undesiredToken;
        path[1] = desiredToken;

        uint amountOutSwap = router.swapExactTokensForTokens(
            amountInToSwap,
        // we must get at least this much from the swap to meet the minDesiredTokenOut parameter
            minDesiredTokenOut > amountOutToTransfer ? minDesiredTokenOut - amountOutToTransfer : 0,
            path,
            to,
            deadline
        )[1];

        // we do this after the swap to save gas in the case where we do not meet the minimum output
        if (to != address(this)) {
            TransferHelper.safeTransfer(desiredToken, to, amountOutToTransfer);
        }
        amountDesiredTokenOut = amountOutToTransfer + amountOutSwap;
    }

    // burn the liquidity and then swap one of the two tokens to the other
    // enforces that at least minDesiredTokenOut tokens are received from the combination of burn and swap
    function removeLiquidityAndSwapToToken(
        address undesiredToken,
        address desiredToken,
        uint liquidity,
        uint minDesiredTokenOut,
        address to,
        uint deadline
    ) external returns (uint amountDesiredTokenOut) {
        return _removeLiquidityAndSwap(
            msg.sender, undesiredToken, desiredToken, liquidity, minDesiredTokenOut, to, deadline
        );
    }

    // only WETH can send to this contract without a function call.
    receive() payable external {
        require(msg.sender == address(weth), 'CombinedSwapAddRemoveLiquidity: RECEIVE_NOT_FROM_WETH');
    }

    // similar to the above method but for when the desired token is WETH, handles unwrapping
    function removeLiquidityAndSwapToETH(
        address token,
        uint liquidity,
        uint minDesiredETH,
        address to,
        uint deadline
    ) external returns (uint amountETHOut) {
        // do the swap remove and swap to this address
        amountETHOut = _removeLiquidityAndSwap(
            msg.sender, token, address(weth), liquidity, minDesiredETH, address(this), deadline
        );

        // now withdraw to ETH and forward to the recipient
        weth.withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }
}
```

## 三、源码简要学习

pragma与import。可以看到导入的内容比较多，和Router合约的导入相比，多了一个IUniswapV2Pair.sol和一个Babylonian.sol。多出来的分别为交易对接口和一个计算平方根的工具库。

合约定义，本身没有什么可讲的。有用的是它的注释，介绍了合约功能及实现流程。

using SafeMath for uint;，前面已经学习过了。

接下来是三个状态变量定义，它们都是合约类型（每个合约都是一个不同的合约类型）。分别为UniswapV2的factory合约实例，Router合约实例和WETH合约实例。

constructor，构造器。这里构造器参数直接使用了合约类型的变量而不是地址类型的变量。 这个和我们平常的用法不太一致，不过合约类型它对外ABI类型仍然为地址类型。经过测试，外部部署时这里直接使用地址类型作为构造器参数是可行的。但是如果在合约内创建该合约（使用new创建），构造器参数必须为合约类型，不能为地址类型。

approveRouter函数，将单资产的代币进行授权，授权对象为Router合约，授权额度为用户输入。注意，这里是本合约进行授权，而不是用户进行授权。因为Router合约最后转移的是本合约的代币。它的注释解释了它的逻辑，但是重新授权为一个新值前清除了原来的授权，为什么这样做呢？估计是为了更保险吧，因为你不知道第三方ERC20合约到底是怎样实现的。

calculateSwapInAmount函数。核心函数，计算单资产注入时用户需要先分离多少资产先进行交换。它的两个输入参数分别为当前交易对中某种资产数量和用户欲注入的单资产数量。注释中提到这个计算和交易对中另一种资产没有关系，但具体怎么计算出来的，目前笔者还不清楚。

_swapExactTokensAndAddLiquidity函数。一个内部函数，看名称就知道，单资产注入时先交换资产然后增加流动性。多个外部接口使用相同的逻辑，所以把相同提取成了一个独立的内部函数。函数输入参数：

from是从本合约还是从哪转移资产。
tokenIn与otherToken。交易对中单资产注入的代币地址及另一种代币地址。
amountIn，用户拟注入的总数量，其中一部分会先进行交易，兑换成另一种代币。
minOtherTokenIn，中间过程兑换成另一种代币的最小数量`。
to，接收流动性地址。
deadline，最晚交易时间。
函数输出参数：

amountTokenIn，拟注入的单资产中，参与交易（兑换）部分的数量。
amountTokenOther，中间过程兑换成另一种代币的数量。
liquidity，最后得到的流动性。
函数代码：

前四行，首先，得到交易对中欲注入的那种资产的数量（使用工具库函数计算）。接着，调用calculateSwapInAmount函数计算拟注入的资产中参与交易（兑换）的数量。
5-7行。如果拟注入的资产来源不是本合约，就先将所有拟注入的资产转移到本合约（这样本合约就有相应资产了）。这个过程中会需要授权转移。
第8行。本合约对注入的资产进行授权，授权对象为路由合约，授权额度为拟注入的资产数量。
接下来一对{}里的内容是调用Router合约的swapExactTokensForTokens方法，将swapInAmount数量的注入资产兑换成另一种资产。注意接收地址为本地址，因为接下来还要用接收的另一种资产实现提供流动性功能。后面为什么还有一个[1]呢，因为swapExactTokensForTokens函数返回的是两种代币的参与数量，是一个数组。数组内元素顺序和交易路径一致，所以[1]代表得到的另一种资产数量。
approveRouter(otherToken, amountTokenOther);对得到的另一种资产也进行授权（不然提供流动性时Router合约无法转移走）。授权对象为Router合约，额度就是得到的另一种资产数量（也是注入数量）。
amountTokenIn = amountIn.sub(swapInAmount);计算实际参与提供流动性的初始资产数量，为拟注入的数量减去参与交易的数量。
最后就是调用Router合约的addLiquidity函数进行提供流动性操作。可以看一下注释的一些解释。
swapExactTokensAndAddLiquidity函数。用户实际调用的外部接口，欲注入的单向资产为普通ERC20代币。此时，直接调用_swapExactTokensAndAddLiquidity函数即可。

swapExactETHAndAddLiquidity函数。用户实际调用的外部接口，欲注入的单向资产为ETH。因为用户欲注入的资产为ETH，所以UniswapV2交易对必定为WETH/ERC20交易对。这个函数和上面的函数相比，仅多了一个将ETH兑换成WETH的步骤，其它几乎完全一样。注意到因为兑换后的WETH在本合约（不在用户身上），所以调用_swapExactTokensAndAddLiquidity函数时第一个参数为address(this)。

_removeLiquidityAndSwap函数。和_swapExactTokensAndAddLiquidity函数类似，不过是移除流动性然后交易，可以看出它和_swapExactTokensAndAddLiquidity函数的流程刚好相反。大家参照上面的_swapExactTokensAndAddLiquidity函数来看一下本函数的输入参数和输出参数。undesiredToken代表另一种资产，desiredToken代表自己最后想要的资产。注意，先移除流动性然后交易没有计算优化值，和普通的分开操作没有区别。我们直接来看函数代码：

第一行获取交易对地址
第二行将欲移除的流动性转移到本合约。
第三行对流动性进行授权，授权对象为Router合约，额度为欲移除的流动性的数值。
接下来是一个Router合约的removeLiquidity调用，移除流动性，提取两种资产。注意接收地址为本合约地址，因为后面还要交易呢。它返回两个值，就是提取的两种资产的值。它们的顺序就是输入参数中undesiredToken和desiredToken顺序，与之相对应。
approveRouter(undesiredToken, amountInToSwap);，对不想要的另一种资产进行授权，对象为Router合约，额度为全部数量。
接下来三行构建一个交易路径，为交易资产做准备。
接下来调用Router合约的swapExactTokensForTokens方法，将不想要的另一种资产兑换成想要的资产。这里的[1] 意义和上面讲到的类似，为交易得到的资产数量。同时还需要注意它设置的最小得到数量的逻辑：如果先前提取时得到的数量已经超过了用户定义的最小值，这里就不需要了，设置为0；如果小于怎么办？那么交易至少要得到两者之间的差额（也就是最小值设置），否则无法达到满足用户预期。
if (to != address(this))代码断，如果交易的接收地址不为本合约地址，假如为外部地址。因为此时移除流动性时提取的资产还在本合约中（与to不一致），所以需要将提取的资产也发送到to地址去。如果为本合约地址，说明所有得到的资产全在本合约中，同to一致，无需处理。
最后一行计算得到的单资产总数量。数值为提取的数量加上兑换的数量。
removeLiquidityAndSwapToToken函数。学习了_removeLiquidityAndSwap函数，这个就很简单了，它是用户调用的外部接口，得到单一ERC20代币。本函数直接调用了_removeLiquidityAndSwap函数。

receive函数。只接受WETH合约发送过来的ETH，因为本合约只与WETH合约发生ETH相互发送（用于ETH/WETH兑换）。

removeLiquidityAndSwapToETH函数，也很简单，只不过将得到的单一资产变成了ERC20代币。首先直接调用_removeLiquidityAndSwap得到WETH这种单一资产（注意此时to地址为本合约，因为用户指定得到ETH，需要再兑换一下）。接着将WETH兑换成ETH，最后将得到的ETH发送给接收者地址to。
