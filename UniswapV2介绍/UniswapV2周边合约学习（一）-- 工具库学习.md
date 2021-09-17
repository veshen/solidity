# UniswapV2周边合约学习（一）-- 工具库学习

>记得朋友圈看到过一句话，如果Defi是以太坊的皇冠，那么Uniswap就是这顶皇冠中的明珠。Uniswap目前已经是V2版本，相对V1，它的功能更加全面优化，然而其合约源码却并不复杂。本文为个人学习UniswapV2源码的系列记录文章。

UniswapV2的周边合约主要用做外部账号和核心合约之间的桥梁，也就是用户 => 周边合约 => 核心合约。UniswapV2周边合约主要包含接口定义，工具库、Router和示例实现这四部分， 这次我们先来学习它的工具库。

UniswapV2周边合约的工具库包含两个部分，一部分是直接写在项目里的，有三个合约：SafeMath，UniswapV2Library和UniswapV2OracleLibrary。另外一部分是Node.js依赖库，需要使用yarn安装的，也包含几个库。这其中SafeMath就是简单的防溢出库，在前面的系列学习中已经讲过，这里不再学习研究。

建议读者在开始学习之前阅读我的另一篇文章：UniswapV2介绍 来对UniswapV2的整体机制有个大致了解，这样更有助于理解源码。

## 一、UniswapV2Library
### 1.1、源码
该库的源码也只有82行，相对比较简单，照例先贴源码：

```
pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
```

### 1.2、学习

首先，我们要注意到该库中所有的函数都是internal类型的。为什么呢，因为所有外部库函数调用都是真实的EVM函数调用，它会有额外的开销 。当然外部库函数调用的参数类型更广泛。

- 第一行用来指定Solidity版本高于或者等于0.5.0
- 第二行用来导入IUniswapV2Pair.sol，也就是交易对的接口，注意它是使用Node.js的module导入的。
- 第三行导入SafeMath，注意它是正常使用相对路径导入的
- 第四行，library *UniswapV2Library* { 库定义。
- 第五行，在Uint类型上使用SafeMath。
- sortTokens函数。对地址进行从小到大排序并验证不能为零地址。
- pairFor函数。注释中已经指出它是计算生成的交易对的地址的。具体计算方法可以分为链下计算和链上合约计算。合约计算的方法在学习核心合约factory时已经讲了。这里需要注意的是init code hash的计算，也可以链上合约计算或者链下计算，当然链下计算更方便一些。但是这里会有个小坑哟，链下计算方法及坑是什么我这里卖个关子就不讲了，大家有兴趣的可以在github上看一下Issues，记得关闭的也要看的，看完就可以明白了。
- getReserves函数。获取某个交易对中恒定乘积的各资产的值。因为返回的资产值是排序过的，而输入参数是不会有排序的，所以函数的最后一行做了处理。
- quote函数。根据比例由一种资产计算另一种资产的值，很好理解。
- getAmountOut函数。A/B交易对中卖出A资产，计算买进的B资产的数量。注意，卖出的资产扣除了千之分三的交易手续费。其计算公式为：
  - 初始条件 `A * B = K`
  - 交易后条件 `( A + A0 ) * ( B - B0 ) = k`
  - 计算得到 `B0 = A0 * B / ( A + A0)`
  - 考虑千分之三的手续费，将上式中的两个A0使用997 * A0 /1000代替，最后得到结果为 B0 = 997 * A0 * B / (1000 * A + 997 * A0 )
- getAmountIn函数。A/B交易对中买进B资产，计算卖出的A资产的数量。注意，它也考虑了手续费。它和getAmountOut函数的区别是一个指定卖出的数量，一个是指定买进的数量。因为是恒定乘积算法，价格是非线性的，所以会有两种计算方式。其计算公式为：
  - 初始条件 A * B = K
  - 交易后条件 ( A + A0 ) * ( B - B0 ) = k
  - 计算得到 A0 = A * B0 / ( B - B0)
  - 考虑千分之三的手续费，A0 = A0 * 1000 / 997，所以计算结果为 A0 = A * B0 * 1000 / (( B - B0 ) * 997)
  - 因为除法是地板除，但是卖进的资产不能少（可以多一点），所以最后结果还需要再加上一个1。
- getAmountsOut函数。计算链式交易中卖出某资产，得到的中间资产和最终资产的数量。例如 A/B => B/C 卖出A，得到BC的数量。
- getAmountsIn函数。计算链式交易中买进某资产，需要卖出的中间资产和初始资产数量。例如 A/B => B/C 买进C，得到AB的数量。因为从买进推导卖出是反向进行的，所以数据是反向遍历的。
## 二、UniswapV2OracleLibrary
### 2.1、源码

该库的源码很短，只有35行，只有两个函数。

```
pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}
```

### 2.2、学习

- 第一行用来指定Solidity版本高于或者等于0.5.0
- 接下来两行导入语句分别导入交易对合约接口和自定义的浮点数库。合约接口见核心合约学习相关文章，浮点数库在下面介绍。
- 接下来的注释阐述了该库的用处，计算当前累计价格，同时避免同步调用，节省手续费。
- library UniswapV2OracleLibrary { 库定义
- using FixedPoint for *;在所有数据类型上使用FixedPoint库，从中可以看出库中也可以使用别的库，语法是一样的。
- currentBlockTimestamp获取当前区块时间，注意这里和交易对合约中的处理方式一样，取模操作。然而就算溢出了，直接进行类型转换也会得到和取模操作相同的值。这个问题我在核心合约学习三中已经更新过了，开发者给出答案了。
- currentCumulativePrices函数。计算当前区块累积价格。如果当前区块交易对合约已经计算过了（两个区块时间一致），则跳过；如果没有，则加上去。注意它是view函数，并未更新任何状态变量，这个累计值是计算出来的。
- 
## 三、FixedPoint库

因为UniswapV2OracleLibrary库的源码中使用了FixedPoint库，所以我们顺便也学习一下该库。注意，该库并不是以编写源码的方式保存为文件直接导入的，而是通过Node.js模块导入，属于依赖库。查看其周边合约的README.md可以看到，运行yarn命令来安装所有依赖。

### 3.1、源码

下面是该库的源码：

```
pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}
```

### 3.2、学习

- 第一行指定了使用的Solidity版本
- 第二行是库定义，注意库没有继承。
- 接下来定义两个数据结构，一个是uq112x112，加起来就是224位，所以它的字段只有一个uint224的_x。一个是uq144x112，加起来就是256位，所以它的字段为uint的_x。注意它的注释分别代表取值范围和精度（小数）。
- uint8 private constant RESOLUTION = 112;定义不同大小数据转换时左移或者右移的位数。
- encode函数。将uint112转成uq112x112结构。
- encode144函数。将uint112转成uq114x112结构。
- div函数。一个uq112x112类型除于一个uint112，注意先uint112转化成了uint224，结果也是一个uq112x112。（两个112位分别代表数值和精度）。
- mul函数。将一个uq112x112和一个uint相乘法。注意，做了防溢出处理，结果是一个uq144x112，相比uq112x112，最左边的32位是保存的相对uint224的溢出位。
- fraction函数，用来在两个uint112相除时提高精度，将分子左移112位，那么结果的左边112位就是值，右边的112位相当于小数位。用于UniswapV2的价格计算当中。
- decode函数，将一个uq112x112（uint224）右移112位并将结果转换成uint112，相当于右边112位小数位被截断了。
- decode144函数，同上，只是数据类型变成了uq144x112（uint256)。

因为本库主要功能是提高价格计算时的精度，在UniswapV2周边合约中，该库的绝大部分函数仅在预言机示例合约中使用。

## 四、TransferHelper库

有个简单的库也要提一下，它就是TransferHelper库，它也是通过依赖安装导入的。主要目的是用来统一处理标准ERC20代币和非标准ERC20代币之间部分函数的返回值问题（主要是转移代币和授权的返回值）。它通过使用一个低级的call函数调用来代替正常的合约调用，并对执行结果和返回值做处理。这样处理的目的见UniswapV2介绍。

注意：使用call调用合约必须提供函数的选择器（如果存在），计算方式注释中已经写明了。

### 4.1、源码

```
pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
```
### 4.2、学习

- safeApprove授权函数。被调用函数可以有返回值（为true)或者无返回值，均会被视为成功。
- safeTransfer直接转移代币函数，返回值处理同上。
- safeTransferFrom授权转移代币函数，返回值处理同上。
- safeTransferETH发送ETH，注意等式右边的语法：(bool success,) = to.call{value:value}(new bytes(0));。value代表发送的ETH数量（单位为wei)，new bytes(0)代表为空数据payload。

注意：这里有点小瑕疵。虽然本库代码第一行指定了Solidity版本为>=0.6.0，但是(bool success,) = to.call{value:value}(new bytes(0));使用的语法在0.6.2版本才能编译通过。不过单独看有这么一点小问题，但是因为使用该库的合约源码均指定Solidity版本为0.6.6，所以联合使用起来使用没有问题。当然如果能将pragma solidity >=0.6.0;换成pragma solidity >=0.6.2;就更精确了。

## 五、其它依赖

node_modules/@uniswap/lib/contracts/libraries/目录下还有其它一些依赖库，主要是进行一些字符串或者字符操作，这里就不一一学习了。需要提到一点的是在PairNamer.sol源码中，出现了string private constant TOKEN_SYMBOL_PREFIX = '🦄';那个独角兽图标其实是一个Unicode字符。在Solidity中，字符串字面值是支持unicode的。🦄字符从UniswapV1起开始使用，它的详细说明网址为:https://emojipedia.org/unicorn/。当然如果你愿意，可以挑选一个你喜欢的其它Unicode字符来替换它。

不过这里同样存在编译器版本的问题，在PairNamer.sol源码中，给出了pragma solidity >=0.5.0;。但实际上在0.7.0后，在有效的UTF-8序列中插入Unicode字符需要增加unicode前缀，例如：

`string memory a = unicode"Hello 😃";`

UniswapV2未使用Solidity 0.7.0以上版本，所以这里不需要。如果使用加unicode的新语法，Solidity版本必须0.7.0以上。

最后一点，库其实只用部署一次，在编译时将它的地址链接到使用的合约即可（使用一些工具自动部署时看不出来，可以使用truffle进行手动部署库再进行链接）。但是库源码一般都不大，一个新项目基本上都会重新部署一个相同的库（例如SafeMath），而不会重用以前部署好的库。
