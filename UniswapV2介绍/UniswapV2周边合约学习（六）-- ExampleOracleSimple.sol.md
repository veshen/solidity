# UniswapV2周边合约学习（六）-- ExampleOracleSimple.sol


## 一、ExampleOracleSimple合约介绍

该合约位于examples目录下，比较简单，为一个以UniswapV2交易对作为价格预言机的示例合约。由于智能合约没有定时机制，所以必须每隔一段时间（周期）来更新价格。

因为这一个示例合约涉及到了UniswapV2中的价格表示，希望没有读过UniswapV2介绍的读者能读一下，对它的价格机制有一个大致了解。同时也需要阅读一下序列文章中核心合约学习中交易对学习的记录文章：UniswapV2核心合约学习（3）——UniswapV2Pair.sol，那里面对价格计算及溢出机制有详细的学习。

## 二、合约源码

照例先贴出源码：

```
pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

import '../libraries/UniswapV2OracleLibrary.sol';
import '../libraries/UniswapV2Library.sol';

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract ExampleOracleSimple {
    using FixedPoint for *;

    uint public constant PERIOD = 24 hours;

    IUniswapV2Pair immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    constructor(address factory, address tokenA, address tokenB) public {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'ExampleOracleSimple: NO_RESERVES'); // ensure that there's liquidity in the pair
    }

    function update() external {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'ExampleOracleSimple: PERIOD_NOT_ELAPSED');

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint amountOut) {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, 'ExampleOracleSimple: INVALID_TOKEN');
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}
```

## 三、源码学习
第一行，指定Solidity版本。

2-4行，导入V2版本的facotry和交易对合约及一个自定义的浮点数库（以整数模拟浮点数），注意这三个依赖库需要在项目根目录下运行yarn合约来安装。

5-6行，导入项目自定义的工具库，一个用于交易对一个用于价格计算。这两个库的简要说明见序列文章中周边合约工具库学习的记录文章。

contract ExampleOracleSimple { 合约的定义，上面的注释提到了价格为至少一个周期内的平均值，但是可以使用更长时间的间隔。

using FixedPoint for *;在所有类型上使用自定义浮点数工具库函数，实际上是在几个整数类型（结构）上使用。有兴趣的读者可以在使用yarn合约安装依赖后，在项目的根目录下的node_modules目录下相应位置找到该工具库源码。不过笔都也没有怎么看这个库的源码。

uint public constant PERIOD = 24 hours;定义平均价格的取值周期，周期太短是无法反映一段时间的平均价格的，这个取值多少可以自己定义。注意本行中出现的hours是时间单位，就是字面值1小时，转化成秒就是3600秒。当然这里是整数，只是取的数值，没有后面的秒。

```
IUniswapV2Pair immutable pair;
address public immutable token0;
address public immutable token1;
```

使用状态变量记录V2交易对的实例和交易对两种代币地址，这表明该合约是某固定交易对的价格预言机。

```
uint    public price0CumulativeLast;
uint    public price1CumulativeLast;
uint32  public blockTimestampLast;
```

记录当前两种代币的累计价格及最后更新区块时间的状态变量。

```
FixedPoint.uq112x112 public price0Average;
FixedPoint.uq112x112 public price1Average
```

记录两种平均价格的状态变量。注意，价格是个比值，为uq112x112类型（前112位代表整数，后112位代表小数，底层实现是个uint224）。

constructor构造器，输入参数为V2版本的factory地址和交易对的两种代币地址。

1- 2行先由工具库函数计算交易对的地址，然后实例化成一个临时变量，再将临时变量赋值给状态变量。为什么要使用一个临时变量，个人猜想是因为后面要参与到大量计算，不用重复读取状态变量，可以节省gas吧（类似的用法在前面的学习中例如核心合约学习多次出现）。
3-4行获取交易对排过序的两种代币地址并赋值给相应状态变量。这里和构造器参数输入的代币地址略有不同，输入的地址是乱序的；这里得到的是排过充的，其中token0对应的就是price0,amount0,reserve0等等。
5-6行获取当前交易对两种资产（ERC20代币）的价格，注意价格为一个比值。
7-9行用来获取当前交易对两种资产值及最近更新的区块时间（就是合约部署时最近更新价格的区块时间）。因为使用元组赋值，元组内的变量必须提前定义。
最后一行注释讲了，该交易对必须有流动性，不能为空交易对。
update函数，用来更新记录的平均价格。

1-2行使用库函数来计算交易对当前区块的两种累计价格和获取当前区块时间（具体实现逻辑需要查看UniswapV2OracleLibrary合约源码）。这个为什么使用库函数计算呢，因为交易对的记录的是上一次发生交易所在区块的累计价格和区块时间，并不是当前区块的（因为当前区块可能在查询时还未发生过交易对的交易）。在UniswapV2OracleLibrary对应的函数中有将这个区块差补上来的逻辑，注意，价格累计在每个交易区块只更新一次。
第3行用计算当前区块时间和上一次本合约记录的区块时间间隔，注意它是考虑到溢出了的。详情见序列文章中核心合约交易对的学习。
第4行验证这个时间间隔必须大于一个周期。必须统计超过一个周期的价格平均值。
5-6行来更新当前价格平均值（平均价格由累计价格差值除于时间差值得到）。注意FixedPoint.uq112x112()语法代表实例化一个结构。uint224()语法代表类型转换。这里注释也讲了，直接使用了截断来转化为价格，为什么这么做呢？参考一下交易对合约学习中的分析，因为就算有溢出，平均价格的计算总是正确的，而平均价格为uq112x112类型，高位用不上（累计价格高位用得上，代表溢出），所以这里直接截断转化为uint224类型（个人理解也许不对）。
7-9行更新当前合约保存的最新的价格累计值及最近更新区块时间。
consult函数。价格查询函数，利用当前保存的最新平均价格，输入一种代币的数量（和地址），计算另一种代币的数量。函数使用了一个if - else语句来判断输入的代币是token0还是token1，使用相应的平均价格计算。注意，这里计算的结果还有模拟的小数部分，因为最后输出必须为一个整数（代币数量为uint系列类型，没有小数，注意不要和精度的概念弄混），所以调用了decode144()函数，直接将模拟小数的较低112位移走了（右移112位）。

注意这里的语法price1Average.mul(amountIn).decode144()中的mul，它不是普通SafeMath中的用于uint的mul，而是FixedPoint中自定义的mul。它返回一个uq144x112，所以才能接着调用decode144函数。

好了，本次学习到此结束了，下一次计划学习examples目录下的ExampleSlidingWindowOracle.sol。
