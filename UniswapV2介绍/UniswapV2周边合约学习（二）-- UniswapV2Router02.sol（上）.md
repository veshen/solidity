# UniswapV2周边合约学习（二）-- UniswapV2Router02.sol（上）

## 一、Router合约介绍

UniswapV2的周边合约主要作用是作为用户和核心合约之间的桥梁。也就是用户 => 周边合约 => 核心合约。UniswapV2周边合约主要包含接口定义，工具库和核心实现这三部分，在上一篇文章里已经学习了它的工具库函数，这次我们主要学习其核心实现。

UniswapV2周边合约的核心实现包含UniswapV2Router01.sol和UniswapV2Router02.sol，这里我们把它简称为Router1和Router2。查看它们实现的接口我们可以看到，Router2仅在Router1上多了几个接口。那为什么会有两个路由合约呢，我们到底用哪个呢？查看其官方文档我们可以得到：

Because routers are stateless and do not hold token balances, they can be replaced safely and trustlessly, if necessary. This may happen if more efficient smart contract patterns are discovered, or if additional functionality is desired. For this reason, routers have release numbers, starting at 01. This is currently recommended release, 02.

上面那段话的大致意思就是因为Router合约是无状态的并且不拥有任何代币，因此必要的时候它们可以安全升级。当发现更高效的合约模式或者添加更多的功能时就可能升级它。因为这个原因，Router合约具有版本号，从01开始，当前推荐的版本是02。

这段话解释了为什么会有两个Router，那么它们的区别是什么呢？还是来看官方文档：

UniswapV2Router01 should not be used any longer, because of the discovery of a low severity bug and the fact that some methods do not work with tokens that take fees on transfer. The current recommendation is to use UniswapV2Router02.

这段话是讲因为在Router1中发现了一个低风险的bug，并且有些方法不支持使用转移的代币支付手续费，所以不再使用Router1，推荐使用Router2。

因此本文也是学习的UniswapV2Router02.sol，它的前半部分主要是流动性供给相关的函数（功能），后半部分主要是交易对资产交换相关的函数（功能）。由于篇幅较长，因此该合约学习计划分为上、下两个部分来学习，内容分别为流动性供给函数和资产交换函数。这次先学习流动性供给部分。

建议对UniswapV2不熟的读者在开始学习之前阅读我的另一篇文章：UniswapV2介绍 来对UniswapV2的整体机制有个大致了解；当然也建议阅读前面的系列文章，特别是核心合约学习部分，这样更有助于理解源码。

UniswapV2周边合约在Github上的地址为: uniswap-v2-periphery

## 二、源码中的公共部分
UniswapV2Router02.sol源码的公共部分从第一行开始，到回调函数receive结束。主要是导入文件和公共变量定义、函数修饰符及构造器等。

第一行，指定Solidity版本

第2-3行，导入Node.js依赖库，注意导入的文件也是.sol结尾，第一个为核心合约factory的接口，第二个为TransferHelper库。这个库在我的上一篇文章周边合约工具库学习时有简单提及。

4-8行，导入项目内其它接口或者库。分别为本合约要实现的接口，自定义的工具库（在周边合约学习一中有介绍），SafeMath标准ERC20接口和WETH接口。

`contract *UniswapV2Router02* is IUniswapV2Router02 { `合约定义，本合约实现了IUniswapV2Router02接口。

using SafeMath for uint;很常见，在uint上使用SafeMath，防止上下溢出。

```
address public immutable override factory;
address public immutable override WETH;
```

这两行代码使用两个状态变量分别记录了factory合约的地址WETH合约的地址。这里有两个关键词immutable和override需要深入学习一下。

immutable，不可变的。类似别的语言的final变量。也就是它初始化后值就无法再改变了。它和constant（常量）类似，但又有些不同。主要区别在于：常量在编译时就是确定值，而immutable状态变量除了在定义的时候初始化外，还可以在构造器中初始化（合约创建的时候），并且在构造器中只能初始化，是读取不了它们的值的。并不是所有数据类型都可以为immutable变量或者常量的类型，当前只支持值类型和字符串类型(string)。

override这个很常见。通常用于函数定义中，代表它重写了一个父函数。例如也可以用于函数修饰符来代表它被重写，不过应用于状态变量却稍有不同。

Public state variables can override external functions if the parameter and return types of the function matches the getter function of the variable:

这句话的意思是：如果external函数的参数和返回值同公共状态变量的getter函数相符的话，这个公共状态变量可以重写该函数。但是状态变量本身却不能被重写。我们来找一下它到底重写了哪个函数，在它实现的接口IUniswapV2Router02中，有这么一个函数定义：

function factory() external pure returns (address);，可见factory公共状态变量重写了其接口的external同名函数。

这里有人可能会问，Router2接口定义中不是没有这个函数吗？因为Router2接口继承了Router1接口，Router1接口定义了该函数，Router2接口就自动拥有该函数。

接下来是个ensure构造器修饰符，比较简单，就是判定当前区块（创建）时间不能超过最晚交易时间。代码为：

```
modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
    _;
}
```

接下来是构造器，也很简单，将上面两个immutable状态变量初始化。

```
constructor(address _factory, address _WETH) public {
    factory = _factory;
    WETH = _WETH;
}
```

接下来是一个接收ETH的函数receive。从Solidity 0.6.0起，没有匿名回调函数了。它拆分成两个，一个专门用于接收ETH，就是这个receive函数。另外一个在找不到匹配的函数时调用，叫fallback函数。该receive函数限定只能从WETH合约直接接收ETH，也就是在WETH提取为ETH时。注意仍然有可以有别的方式来向此合约直接发送以太币，例如设置为矿工地址等，这里不展开阐述。

```
receive() external payable {
    assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
}
```

## 三、源码中的流动性供给部分

_addLiquidity函数。看名字为增加流动性，为一个internal函数，提供给多个外部接口调用。它主要功能是计算拟向交易对合约注入的代币数量。函数代码如下：

```
// **** ADD LIQUIDITY ****
function _addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
) internal virtual returns (uint amountA, uint amountB) {
    // create the pair if it doesn't exist yet
    if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
        IUniswapV2Factory(factory).createPair(tokenA, tokenB);
    }
    (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
    if (reserveA == 0 && reserveB == 0) {
        (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
        uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }
}
```

该函数以下划线开头，根据约定一般它为一个内部函数。六个输入参数分别为交易对中两种代币的地址，计划注入的两种代币数量和注入代币的最小值（否则重置）。返回值为优化过的实际注入的代币数量。

函数的前三行，注释说的很清楚，如果交易对不存在（获取的地址为零值），则创建之。

函数的第四行获取交易对资产池中两种代币reserve数量，当然如果是刚创建的，就都是0。

第五行到结束是一个if - else语句。如果是刚创建的交易对，则拟注入的代币全部转化为流动性，初始流动性计算公式及初始流动性燃烧见我的核心合约学习三那篇文章。如果交易对已经存在，由于注入的两种代币的比例和交易对中资产池中的代币比例可能不同，再用一个if - else语句来选择以哪种代币作为标准计算实际注入数量。（如果比例不同，总会存在一种代币多一种代币少，肯定以代币少的计算实际注入数量）。

这里可以这样理解，假定A/B交易对，然后注入了一定数量的A和B。根据交易对当前的比例，如果以A计算B，B不够，此时肯定不行；只能反过来，以B计算A，这样A就会有多余的，此时才能进行实际注入（这样注入的A和B数量都不会超过拟注入数量）。

那为什么要按交易对的比例来注入两种代币呢？在核心合约学习三那篇文章里有提及，流动性的增加数量是分别根据注入的两种代币的数量进行计算，然后取最小值。如果不按比例交易对比例来充，就会有一个较大值和一个较小值，取最小值流行性提供者就会有损失。如果按比例充，则两种代币计算的结果一样的，也就是理想值，不会有损失。

该函数也涉及到了部分UniswapV2Library库函数的调用，可以看上一篇文章周边合约工具库学习。

addLiquidity函数。学习了前面的_addLiquidity函数，这个就比较好理解了。它是一个external函数，也就是用户调用的接口。函数参数和_addLiquidity函数类似，只是多了一个接收流动性代币的地址和最迟交易时间。代码片断为：

```
function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
    TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = IUniswapV2Pair(pair).mint(to);
}
```

这里deadline从UniswapV1就开始存在了，主要是保护用户，不让交易过了很久才执行，超过用户预期。函数返回值是实际注入的两种代币数量和得到的流动性代币数量。

函数的第一行是调用_addLiquidity函数计算需要向交易对合约转移（注入）的实际代币数量。

函数的第二行是获取交易对地址（注意，如果交易对不存在，在对_addLiquidity调用时会创建）。注意，它和_addLiquidity函数获取交易对地址略有不同，一个是调用factory合约的接口得到（这里不能使用根据salt创建合约的方式计算得到，因为不管合约是否存在，总能得到该地址）；另一个是根据salt创建合约的方式计算得到。虽然两者用起来都没有问题，个人猜想本函数使用salt方式计算是因为调用的库函数是pure的，不读取状态变量，并且为内部调用，能节省gas；而调用factory合约接口是个外部EVM调用，有额外的开销。个人猜想，未必正确。

第三行和第四行是将实际注入的代币转移至交易对。

第五行是调用交易对合约的mint函数来给接收者增发流动性。

对于这个合约接口（外部函数），Uniswap文档也提到了三点注意事项：

为了覆盖所有场景，调用者需要给该Router合约一定额度的两种代币授权。因为注入的资产为ERC20代币，第三方合约如果不得到授权（或者授权额度不够），就无法转移你的代币到交易对合约中去。
总是按理想的比例注入代币（因为计算比例和注入在一个交易内进行），具体取决于交易执行时的价格，这一点在介绍_addLiquidity函数时已经讲了。
如果交易对不存在，则会自动创建，拟注入的代币数量就是真正注入的代币数量。
addLiquidityETH函数。和addLiquidity函数类似，不过这里有一种初始注入资产为ETH。因为UniswapV2交易对都是ERC20交易对，所以注入ETH会先自动转换为等额WETH（一种ERC20代币，通过智能合约自由兑换，比例1:1）。这样就满足了ERC20交易对的要求，因此真实交易对为WETH/ERC20交易对。

本函数的参数和addLiquidity函数的参数相比，只是将其中一种代币换成了ETH。注意这里没有拟注入的amountETHDesired，因为随本函数发送的ETH数量就是拟注入的数量，所以该函数必须是payable的，这样才可以接收以太币。函数代码为：

```
function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
    (amountToken, amountETH) = _addLiquidity(
        token,
        WETH,
        amountTokenDesired,
        msg.value,
        amountTokenMin,
        amountETHMin
    );
    address pair = UniswapV2Library.pairFor(factory, token, WETH);
    TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
    IWETH(WETH).deposit{value: amountETH}();
    assert(IWETH(WETH).transfer(pair, amountETH));
    liquidity = IUniswapV2Pair(pair).mint(to);
    // refund dust eth, if any
    if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
}
```

函数的第一行仍旧是调用_addLiquidity函数来计算优化后的注入代币值。正如前面分析的那样，它使用WETH地址代替另一种代币地址，使用msg.value来代替拟注入的另一种代币（因为WETH与ETH是等额兑换）数量。当然，如果WETH/TOKEN交易对不存在，则先创建之。

函数的第二行是获取交易对地址。注意它获取的方式仍然是计算得来。

第三行是将其中一种代币token转移到交易对中（转移的数量为由第一行计算得到）

第四行是将ETH兑换成WETH，它调用了WETH合约的兑换接口，这些接口在IWETH.sol中定义。兑换的数量也在第一行中计算得到。当然，如果ETH数量不够，则会重置整个交易。

第五行将刚刚兑换的WETH转移至交易对合约，注意它直接调用的WETH合约，因此不是授权交易，不需要授权。另外由于WETH合约开源，可以看到该合约代码中转移资产成功后会返回一个true，所以使用了assert函数进行验证。

第六行是调用交易对合约的mint方法来给接收者增发流动性。

最后一行是如果调用进随本函数发送的ETH数量msg.value有多余的（大于amountETH,也就是兑换成WETH的数量），那么多余的ETH将退还给调用者。

removeLiquidity函数。移除（燃烧）流动性（代币），从而提取交易对中注入的两种代币。该函数的7个参数分别为两种代币地址，燃烧的流动性数量，提取的最小代币数量（保护用户），接收者地址和最迟交易时间。它的返回参数是提取的两种代币数量。该函数是virtual的，可被子合约重写。正如前面所讲，本合约是无状态的，是可以升级和替代的，因此本合约所有的函数都是virtual的，方便新合约重写它。下面是该函数的代码片断：

```
// **** REMOVE LIQUIDITY ****
function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
    address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
    IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
    (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
    (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
    require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
}
```

函数的第一行计算两种代币的交易对地址，注意它是计算得来，而不是从factory合约查询得来，所以就算该交易对不存在，得到的地址也不是零地址。

函数的第二行调用交易对合约的授权交易函数，将要燃烧的流动性转回交易对合约。如果该交易对不存在，则第一行代码计算出来的合约地址的代码长度就为0，调用其transferFrom函数就会报错重置整个交易，所以这里不用担心交易对不存在的情况。

函数的第三行调用交易对的burn函数，燃烧掉刚转过去的流动性代币，提取相应的两种代币给接收者。

第四行和第五行是将结果排下序（因为交易对返回的提取代币数量的前后顺序是按代币地址从小到大排序的），使输出参数匹配输入参数的顺序。

第六行和第七行是确保提取的数量不能小于用户指定的下限，否则重置交易。为什么会有这个保护呢，因为提取前可以存在多个交易，使交易对的两种代币比值（价格）和数量发生改变，从而达不到用户的预期值。

用户调用该函数之前同样需要给Router合约交易对流动性代币的一定授权额度，因为中间使用到了授权交易transferFrom。

removeLiquidityETH函数，同removeLiquidity函数类似，函数名多了ETH。它代表着用户希望最后接收到ETH，也就意味着该交易对必须为一个TOKEN/WETH交易对。只有交易对中包含了WETH代币，才能提取交易对资产池中的WETH，然后再将WETH兑换成ETH给接收者。函数代码为：

```
function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
    (amountToken, amountETH) = removeLiquidity(
        token,
        WETH,
        liquidity,
        amountTokenMin,
        amountETHMin,
        address(this),
        deadline
    );
    TransferHelper.safeTransfer(token, to, amountToken);
    IWETH(WETH).withdraw(amountETH);
    TransferHelper.safeTransferETH(to, amountETH);
}
```

因为WETH的地址公开且已知，所以函数的输入参数就只有一个ERC20代币地址。相应的，其中的一个Token文字值也换成了ETH。

函数的第一行直接调用上一个函数removeLiquidity来进行流动性移除操作，只不过将提取资产的接收地址改成本合约。为什么呢？因为提取的是WETH，用户希望得到ETH，所以不能直接提取给接收者，还要多一步WETH/ETH兑换操作。

注意，在调用本合约的removeLiquidity函数过程中，msg.sender保持不变（在另一种智能合约编程语言Vyper语言中，这种场景下msg.sender会发生变化）。

函数的第二行将燃烧流动性提取的另一种ERC20代币（非WETH）转移给接收者。

第三行将燃烧流动性提取的WETH换成ETH。

第四行将兑换的ETH发送给接收乾。

因为调用了removeLiquidity函数，同样需要用户事先进行授权，见removeLiquidity函数分析。

removeLiquidityWithPermit函数。同样也是移除流动性，同时提取交易对资产池中的两种ERC20代币。它和removeLiquidity函数的区别在于本函数支持使用线下签名消息来进行授权验证，从而不需要提前进行授权（这样会有一个额外交易），授权和交易均发生在同一个交易里。参考系列文章中的核心合约学习二中的permit函数学习。函数代码为：

```
function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
) external virtual override returns (uint amountA, uint amountB) {
    address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
    uint value = approveMax ? uint(-1) : liquidity;
    IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
}
```

和removeLiquidity函数相比，它输入参数多了bool approveMax及uint8 v, bytes32 r, bytes32 s。approveMax的含义为是否授权为uint256最大值(2 ** 256 -1)，如果授权为最大值，在授权交易时有特殊处理，不再每次交易减少授权额度，相当于节省gas。这个核心合约学习二中也有提及。v,r,s用来和重建后的签名消息一起验证签名者地址，具体见核心合约学习二中的permit函数学习。

函数的第一行照例是计算交易对地址，注意不会为零地址。

函数的第二行用来根据是否为最大值设定授权额度。

函数的第三行调用交易对合约的permit函数进行授权。

函数的第四行调用removeLiquidity函数进行燃烧流动性从而提取代币的操作。因为在第三行代码里已经授权了，所以这里和前两个函数有区别，不需要用户提前进行授权了。

removeLiquidityETHWithPermit函数，功能同removeLiquidityWithPermit类似，只不过将最后提取的资产由TOKEN变为ETH。代码可以比对removeLiquidityETH函数，因此这里大家可以自己学习一下，只是贴出函数代码：

```
function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
) external virtual override returns (uint amountToken, uint amountETH) {
    address pair = UniswapV2Library.pairFor(factory, token, WETH);
    uint value = approveMax ? uint(-1) : liquidity;
    IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
}
```

`removeLiquidityETHSupportingFeeOnTransferTokens`函数。名字很长，从函数名字中可以看到，它支持使用转移的代币支付手续费（支持包含此类代币交易对）。

为什么会有使用转移的代币支付手续费这种提法呢？假定用户有某种代币，他想转给别人，但他还必须同时有ETH来支付手续费，也就是它需要有两种币，转的币和支付手续费的币，这就大大的提高了人们使用代币的门槛。于是有人想到，可不可以使用转移的代币来支付手续费呢？有人也做了一些探索，由此衍生了一种新类型的代币，ERC865代币，它也是ERC20代币的一个变种。ERC865代币的详细描述见ERC865: Pay transfer fees with tokens instead of ETH。

然而本合约中的可支付转移手续费的代币却并未指明是ERC865代币，但是不管它是什么代币，我们可以简化为一点：此类代币在转移过程中可能发生损耗（损耗部分发送给第三方以支付整个交易的手续费），因此用户发送的代币数量未必就是接收者收到的代币数量。

本函数的功能和removeLiquidityETH函数相同，但是支持使用token支付费用。函数的代码为：

```

// **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
) public virtual override ensure(deadline) returns (uint amountETH) {
    (, amountETH) = removeLiquidity(
        token,
        WETH,
        liquidity,
        amountTokenMin,
        amountETHMin,
        address(this),
        deadline
    );
    TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    IWETH(WETH).withdraw(amountETH);
    TransferHelper.safeTransferETH(to, amountETH);
}
```

我们将它的代码和removeLiquidityETH函数的代码相比较，只有稍微不同：

函数返回参数及removeLiquidity函数返回值中没有了amountToken。因为它的一部分可能要支付手续费，所以removeLiquidity函数的返回值不再为当前接收到的代币数量。
不管损耗多少，它把本合约接收到的所有此类TOKEN直接发送给接收者。
WETH不是可支付转移手续费的代币，因此它不会有损耗。
removeLiquidityETHWithPermitSupportingFeeOnTransferTokens函数。功能同removeLiquidityETHSupportingFeeOnTransferTokens函数相同，但是支持使用链下签名消息进行授权。本函数的代码片断为：

```
function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external virtual override returns (uint amountETH) {
      address pair = UniswapV2Library.pairFor(factory, token, WETH);
      uint value = approveMax ? uint(-1) : liquidity;
      IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
      amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
          token, liquidity, amountTokenMin, amountETHMin, to, deadline
      );
  }
```

参照前面的函数学习可以很容易的看出本函数的代码逻辑，这里大家自己尝试一下。

## 四、流动性供给接口分类
源码中流动性供给的外部接口可以按照是提供流动性还是移除流动性分为两大类，然后再根据初始资产/最终得到资产是ETH还是普通ERC20代币做了进一步区分。然后移除流动性还增加了支持链下签名消息授权的接口，最后移除流动性增加了支持使用转移代币支付手续费的接口。

注：下文中的TOKEN均为ERC20代币。

4.1、增加流动性
addLiquidity，增加流动性，提供的初始资产为TOKEN/TOKEN。
addLiquidityETH，增加流动性，提供的初始资产为ETH/TOKEN。
4.2、移除流动性
removeLiquidity，移除流动性，得到的最终资产为TOKEN/TOKEN。
removeLiquidityETH，移除流动性，得到的最终资产为ETH/TOKEN。
4.3、移除流动性，支持使用链下签名消息授权
removeLiquidityWithPermit函数，移除流动性，支持使用链下签名消息授权，得到TOKEN/TOKEN。
removeLiquidityETHWithPermit函数，移除流动性，支持使用链下签名消息授权，得到ETH/TOKEN。
4.4、移除流动性，支持使用转移代币支付手续费
removeLiquidityETHSupportingFeeOnTransferTokens函数，移除流动性，支持使用转移代币支付手续费，得到ETH/TOKEN。
4.5、移除流动性，同时支持使用链下签名消息授权和使用转移代币支付手续费
removeLiquidityETHWithPermitSupportingFeeOnTransferTokens函数。功能同标题，得到ETH/TOKEN。
从上面分类也可以得出一些其它结论。

增加流动性没有使用链下签名消息授权，为什么呢？因为增加流动性其流动性代币是直接增发，没有使用第三方转移，所以就没有授权操作，不需要permit。

移除流动性时，支付使用转移代币支付手续费最后得到的一种资产为ETH，说明交易对为ERC20/WETH交易对，也就是不支持两个此类代币构成的交易对。原因未知，还需要进一步研究。

既然移除流动性有使用转移代币支付手续费，那么作为同一个交易对，移除流动性之前必定有增加流动性，因此增加流动性时实际上需要支持此类代币的。但是代码中又没有明确写出支持使用转移代币支付手续费接口。为什么呢？

个人猜想，未必正确：

是因为此类代币转移过程中有损耗，而损耗多少未知，所以无法精确知道到底要提前转移多少代币到交易对中，在进行按比例计算时会得到预期外的值。所以写此类接口无法向用户返回相关数量值。
如果用户不考虑返回值的话，直接使用addLiquidity或者addLiquidityETH函数是可以对此类代币进行增加流动性操作的。因为交易对计算注入代币的数量时是以交易对合约地址当前代币余额减去交易对合约资产池中的代币余额，和损耗没有任何关系，因此，增发的流动性是准确的。
至此，UniswapV2Router02.sol学习（上）–流动性借给函数的学习就到此结束了，下一次计划学习UniswapV2Router02.sol（下）–资产交易函数的学习。
