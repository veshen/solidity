# UniswapV2周边合约学习（五）-- ExampleFlashSwap.sol

记得朋友圈看到过一句话，如果Defi是以太坊的皇冠，那么Uniswap就是这顶皇冠中的明珠。Uniswap目前已经是V2版本，相对V1，它的功能更加全面优化，然而其合约源码却并不复杂。本文为个人学习UniswapV2源码的系列记录文章。

一、ExampleFlashSwap合约介绍
该合约为利用UniswapV2交易对中的FlashSwap的先借后还特性，在买卖资产的同时和UnisapV1交易对进行交易，利用价格差进行套利。

二、ExampleFlashSwap合约源码
pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

import '../libraries/UniswapV2Library.sol';
import '../interfaces/V1/IUniswapV1Factory.sol';
import '../interfaces/V1/IUniswapV1Exchange.sol';
import '../interfaces/IUniswapV2Router01.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IWETH.sol';

contract ExampleFlashSwap is IUniswapV2Callee {
    IUniswapV1Factory immutable factoryV1;
    address immutable factory;
    IWETH immutable WETH;

    constructor(address _factory, address _factoryV1, address router) public {
        factoryV1 = IUniswapV1Factory(_factoryV1);
        factory = _factory;
        WETH = IWETH(IUniswapV2Router01(router).WETH());
    }

    // needs to accept ETH from any V1 exchange and WETH. ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory, which takes too much gas
    receive() external payable {}

    // gets tokens/WETH via a V2 flash swap, swaps for the ETH/tokens on V1, repays V2, and keeps the rest!
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address[] memory path = new address[](2);
        uint amountToken;
        uint amountETH;
        { // scope for token{0,1}, avoids stack too deep errors
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        assert(msg.sender == UniswapV2Library.pairFor(factory, token0, token1)); // ensure that msg.sender is actually a V2 pair
        assert(amount0 == 0 || amount1 == 0); // this strategy is unidirectional
        path[0] = amount0 == 0 ? token0 : token1;
        path[1] = amount0 == 0 ? token1 : token0;
        amountToken = token0 == address(WETH) ? amount1 : amount0;
        amountETH = token0 == address(WETH) ? amount0 : amount1;
        }

        assert(path[0] == address(WETH) || path[1] == address(WETH)); // this strategy only works with a V2 WETH pair
        IERC20 token = IERC20(path[0] == address(WETH) ? path[1] : path[0]);
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(address(token))); // get V1 exchange

        if (amountToken > 0) {
            (uint minETH) = abi.decode(data, (uint)); // slippage parameter for V1, passed in by caller
            token.approve(address(exchangeV1), amountToken);
            uint amountReceived = exchangeV1.tokenToEthSwapInput(amountToken, minETH, uint(-1));
            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
            assert(amountReceived > amountRequired); // fail if we didn't get enough ETH back to repay our flash loan
            WETH.deposit{value: amountRequired}();
            assert(WETH.transfer(msg.sender, amountRequired)); // return WETH to V2 pair
            (bool success,) = sender.call{value: amountReceived - amountRequired}(new bytes(0)); // keep the rest! (ETH)
            assert(success);
        } else {
            (uint minTokens) = abi.decode(data, (uint)); // slippage parameter for V1, passed in by caller
            WETH.withdraw(amountETH);
            uint amountReceived = exchangeV1.ethToTokenSwapInput{value: amountETH}(minTokens, uint(-1));
            uint amountRequired = UniswapV2Library.getAmountsIn(factory, amountETH, path)[0];
            assert(amountReceived > amountRequired); // fail if we didn't get enough tokens back to repay our flash loan
            assert(token.transfer(msg.sender, amountRequired)); // return tokens to V2 pair
            assert(token.transfer(sender, amountReceived - amountRequired)); // keep the rest! (tokens)
        }
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
三、源码其它部分学习
第一行，照例是指定Solidity版本

第二行，导入IUniswapV2Callee接口，该接口定义了一个接收到代币后的回调函数。在Uniswapv2核心合约中的交易对合约的swap函数有这么一行代码：

if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);。这正是调用了该函数。这行代码在用户得到买入的资产后立即调用了，且发生在用户卖出资产之前。用户可以在这个空隙利用uniswapV2Call这个回调函数做自己想做的任意操作，比如说套利等。因此，此回调函数再加上UniswapV2交易对的先买进再卖出机制是实现套利的核心。

接下来六个import函数分别导入UniswapV1版本的factory合约接口和交易对接口，V2版的工具库及Router接口，标准ERC20代币接口和WETH接口。因为V1版本的交易对为ETH/ERC20交易对，所以V2版本的交易对相应为WETH/ERC20交易对，所以需要用到WETH及ERC20接口。

contract ExampleFlashSwap is IUniswapV2Callee {这一行为合约定义，它必须实现IUniswapV2Callee，也就是必须实现uniswapV2Call这个函数，不然无法进行回调会报错重置交易。

IUniswapV1Factory immutable factoryV1;
address immutable factory;
IWETH immutable WETH;
1
2
3
接下来是三个状态变量，分别为V1版本的factory实例，V2版本的factory地址及WETH的实例。为什么这里V2版本的factory为地址类型而不为实例（合约类型）呢？因为下面的IUniswapV2Callee函数会利用该地址进行大量的计算（见工具库），所以这里使用地址类型更方便一些。

接下来是constructor构造器，利用输入参数对上面三个状态变量初始化。注意，WETH实例的初始化不是直接传入的WETH合约地址，而是利用Router合约得到的。其实WETH合约人人都可以部署一个，是可以存在多个的。如果存在这种情况，到底用哪个地址实例化呢？用Router合约用到的那个地址才是一致的，是准确无误的。

receive() external payable {} 这行代码代表可以接收直接发送的ETH，注释的意思和上一篇文章学习中对应的注释类似，这里不再重复了。

四、uniswapV2Call函数学习
uniswapV2Call函数，它的注释清晰的解释了套利的过程。这期间你不需要拥有任何一种交易对中的资产（仅需要有少量的ETH来支付gas费用），俗称空手套白狼。它的四个输入参数为调用者（其实就是最初发起交易的账号）、从V2交易对发送过来的两种资产数量、用户预先定义的数据。

注意上面提到的V2版本交易对的这行代码：

if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);。这就意味着本合约实际上为上述代码中的to，也就是说用户调用交易对合约的swap函数时，输入的接收地址to必须为本合约地址。

下面我们来详细学习该函数：

第一行定义了一个path来保存两种资产的地址。path是路径的意思，也可以代表交易路径（流程）。
第2-3行定义了两个临时变量来记录买进的ETH/TOKEN数量，方便辨识，不然token0与token1你都不知道是什么。
4、13行用来防止stack too deep errors，已经讲过多次，不再重复。
5-6行用来获取V2交易对的两种代币地址。这里msg.sender就是V2的交易对，因为本函数是从V2交易对调用的。见上面列出的那行调用代码。
第7行用来验证调用者（交易对）地址和使用UniswapV2工具库算出来的地址相同，确保调用者就是V2交易对，不是假的或者伪装的。
第8行注释说的很清楚，单向的。也就是只能卖出一种资产，得到另一种资产。不能两种资产都卖，虽然UniswapV2交易对支持这种操作。但是这里套利是不支持这种操作的，所以只能得到一种资产，其中必定有一种资产为0。那有没有两种资产都为0呢？没有这种可能，在UniswapV2交易对中对买进的资产做了限制，至少要买进一种（大于0）。
第9行和第10行就很明显了，设置path[0]为卖出的资产（买进的为0），path[1]为买进的资产，也就是交易路径为path[0] => path[1]。这里需要说明，UniswapV2交易对调用此函数时提供的输入参数amount0及amount1是和token0及token1对应的，也就是token0的买进数量为amount0。
第11行用来设置amountToken数值。如果token0为WETH地址，那么另一种资产必为TOKEN，所以其数值为amount1；否则就是本资产token0，对应的数值为amount0。
第12行用来设置amountETH数值。逻辑同上。
第14行进一步验证PATH中必须有一种地址为WETH地址，当然你也可以验证token0或者token1必须有一个为WETH地址，它们是等效的。注释讲了用来确保它是V2中的包含WETH的交易对（否则无法和V1交易对套利），前面第7行只验证了必须为V2交易对。
第15行用来获取同时涉及到两种版本交易对的ERC20代币实例。
第16行用来获取V1版本相应交易对的实例，它调用了V1版本的factory中的getExchange接口来获取包含该ERC20代币（15行那个实例）的交易对地址。
接下来是一个if - else语句来根据从UniswapV2交易对得到的是普通ERC20代币还是ETH分情况和UniswapV1的交易对进行交易，最后将得到的另一种资产支付给UniswapV2交易对，自己留下剩余的，实现套利的目的。
如果是amountToken > 0，那就是从UniswapV2交易对得到了普通ERC20代币，则接着进行：
第18行将随交易发送的数据data解码成uint格式，并设置成为minETH的值。这个minETH是在V1交易对交易时指定得到的ETH最小值。这个解码的语法abi.decode这里已经是第二次使用了。第一次使用在核心合约中的交易对合约的_safeTransfer函数中：abi.decode(data, (bool))，大家可以自己对照看一下。
第19行对V1版本的交易对进行获得的代币的授权，因为V1版本交易对是授权交易，不是先转移资产再交易，所以必须授权。
第20行调用V1版本交易对相应的函数将TOKEN交易成ETH，也就是卖出TOKEN，得到ETH。参数分别是卖出的TOKEN数量，指定获取的ETH最小数量及最晚交易时间。
第21行根据UniswapV2的工具库计算需要支付给UniswapV2交易对的另一种资产WETH的数值。注意：getAmountsIn函数返回的是一个数组，它的第一个元素就是卖出的初始资产的数量。具体分析可以参考序列文章中的周边合约学习中的Router合约学习。
第22行验证从V1交易对换回的ETH数量必须大于欲支付给V2交易对的WETH数量，否则不够支付，交易会重置。这里可以看到验证时用了assert函数，但是我们有时也会在合约中看到使用require函数验证。那么什么时候用require什么时候用assert呢？一般的原则为：当验证直接外界输入时，使用require；当验证内部结果时，使用assert。可以看到这里是验证中间的一个计算结果，所以使用了assert。
第23行，将ETH兑换成等额的欲支付数量的WETH。从第22行知道，这里ETH没有兑换完，还有剩余的，这就是盈利。
第24行，将欲支付数量的WETH转移到V2交易对（msg.sender），这里就是先借后还的“还”。那什么时候开始借的呢，从调用本函数之前就借给本合约（转移资产到本合约）了。
第25-26行，将剩余的ETH发送给调用者（也就是初始用户），并验证发送是否成功。这里使用了一个低级函数call，它如果执行失败，并不会重置整个交易，而是返回一个false，所以这里必须验证返回值。这里为什么不使用更高级的address类型的transfer或send成员呢。个人猜想原因有：
不易和WETH.transfer这种调用语句相区分，可能引起阅读上的混淆；
transfer或send 必须在address payable类型上使用，需要使用payable(sender)来转换。
因为transfer或send函数限定了随函数传输的gas为2300。万一接收地址是一个合约，它还需要接收ETH后再做别的事，这时便会引起out of gas，导致交易失败。使用call可以将所有能得到的gas都传输过去，利于接收方再执行其它操作。
小提示，不管是用transfer或send还是call来发送ETH，接收地址如果是合约的话，必须有相应接收ETH的回调函数，例如本合约中出现的receive，否则交易会失败。
如果是else，那就是amountETH > 0，也就是从UniswapV2交易对得到的是WETH，需要使用它从V1交易对中兑换出来TOKEN，然后再支付TOKEN给V2版本的交易对。
第28行，解码获得用户输入的最小token数量。
第29行，将所有WETH兑换成等额ETH，以便接下来和V1交易对交易。
第30行，将所有ETH在V1交易对中交易成TOKEN。
第31行，利用UniswapV2的工具库计算需要支付给UniswapV2交易对的TOKEN的数量，它和30行得到的数量差就是盈利的数量。
第32行，验证从V1版本换回的TOKEN数量必须大于支付给UniswapV2交易对的TOKEN数量，否则不够支付（盈利为负），会重置交易。
第33行，将支付的TOKEN发送到V2交易对，也就是msg.sender，这里就是先借后还中的“还”。这里因为使用了assert函数，所以要求token.transfer必须返回一个true。所以这个TOKEN对应的代币合约必需满足这个条件（个人猜想因为代币合约是外部合约，是未知的，有可能不返回值或者返回为false，所以必须加一个条件）。
第34行，将剩余的TOKEN发送给最初用户（sender），这里不用考虑接收方（sender）是合约还是外部账号，因为不是发送ETH。使用assert同上。
五、其它
大家从这个合约可以看出，套利合约使用没有门槛，但它并不意味着我们随时都可以使用这个套利合约来套利。个人觉得使用条件及限制有：

首先套利的两个交易对能资产要一致，这是很明显的，你不能tokenA最后套成了tokenB。
其次两个交易对的价格有差别，要有利可套，否则交易回来的资产不够支付的，交易会重置，白白损失手续费。
套利到底能套多少未知，无法提前线下计算。因为它和交易时两种交易对交易执行时价格有关，有可能你执行前是可以套利的，但执行时价格回落 ，你就无法套利了。
实际中也有其它DeFi交易对和UniswapV2交易对之间套利的应用，例如DODO这个项目就有一个套利合约UniswapArbitrageur.sol（不过是针对特定交易对的）。大家有兴趣的可以自己去看一下。

好了，今天的套利合约示例学习就到此结束了，下一次计划学习ExampleOracleSimple.sol(价格预言机示例合约)。
