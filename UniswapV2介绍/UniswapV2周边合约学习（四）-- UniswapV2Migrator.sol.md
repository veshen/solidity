# UniswapV2周边合约学习（四）-- UniswapV2Migrator.sol

记得朋友圈看到过一句话，如果Defi是以太坊的皇冠，那么Uniswap就是这顶皇冠中的明珠。Uniswap目前已经是V2版本，相对V1，它的功能更加全面优化，然而其合约源码却并不复杂。本文为个人学习UniswapV2源码的系列记录文章。

一、Migrator合约介绍
在上一次学习完了Router合约后，UniswapV2核心合约及周边合约的主要部分就已经学习完了，目前就只剩下一些应用示例了。Migrator合约用来将某个交易对的流动性从V1版本迁移到V2版本。其实它也可以算为应用示例的一部分，但作为一种官方实现，并没有放在examples目录。

因为UniswapV1版本的交易对为ETH/ERC20交易对，所以迁移到V2版本必然为WETH/ERC20交易对。在上一次学习中提到，Router合约有一个addLiquidityETH方法就是用来处理提供流动性时一种资产为ETH的。

因此，这个迁移的过程就很清晰了：从V1版本移除流动性，得到ETH和WETH；再调用Router合约的addLiquidityETH方法向V2版本添加流动性（注意，如果V2版本的交易对不存在，会自动创建哟）。最后，如果其中有一种资产有多余（最多一种多余），则退还给流动性提供者（调用者）。

二、合约源码
pragma solidity =0.6.6;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/IUniswapV2Migrator.sol';
import './interfaces/V1/IUniswapV1Factory.sol';
import './interfaces/V1/IUniswapV1Exchange.sol';
import './interfaces/IUniswapV2Router01.sol';
import './interfaces/IERC20.sol';

contract UniswapV2Migrator is IUniswapV2Migrator {
    IUniswapV1Factory immutable factoryV1;
    IUniswapV2Router01 immutable router;

    constructor(address _factoryV1, address _router) public {
        factoryV1 = IUniswapV1Factory(_factoryV1);
        router = IUniswapV2Router01(_router);
    }

    // needs to accept ETH from any v1 exchange and the router. ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory, which takes too much gas
    receive() external payable {}

    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
        external
        override
    {
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(token));
        uint liquidityV1 = exchangeV1.balanceOf(msg.sender);
        require(exchangeV1.transferFrom(msg.sender, address(this), liquidityV1), 'TRANSFER_FROM_FAILED');
        (uint amountETHV1, uint amountTokenV1) = exchangeV1.removeLiquidity(liquidityV1, 1, 1, uint(-1));
        TransferHelper.safeApprove(token, address(router), amountTokenV1);
        (uint amountTokenV2, uint amountETHV2,) = router.addLiquidityETH{value: amountETHV1}(
            token,
            amountTokenV1,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
        if (amountTokenV1 > amountTokenV2) {
            TransferHelper.safeApprove(token, address(router), 0); // be a good blockchain citizen, reset allowance to 0
            TransferHelper.safeTransfer(token, msg.sender, amountTokenV1 - amountTokenV2);
        } else if (amountETHV1 > amountETHV2) {
            // addLiquidityETH guarantees that all of amountETHV1 or amountTokenV1 will be used, hence this else is safe
            TransferHelper.safeTransferETH(msg.sender, amountETHV1 - amountETHV2);
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
三、源码学习
第一行，指定Solidity版本，同边合约的Solidity版本与核心合约的版本并不一样。

六个import语句，导入所需要的工具及相关接口定义。因为它需要调用V1版本的交易对合约，所以导入了V1版本的Factory和Exchange接口。（V1版本没有周边合约，欲交易的资产也不是先转移到交易对）。

contract UniswapV2Migrator is IUniswapV2Migrator 合约定义，定义了本合约必须实现的一些接口。

IUniswapV1Factory immutable factoryV1;使用状态变量记录V1版本的factory。我们和V2版本中Router合约记录factory的状态变量对照一下：address public immutable override factory;，有下面几点需要注意：

本合约的状态变量factoryV1不是public的，这就意味它默认为internal，不能被外部直接访问，但是你设置成public的也是可以的。Router合约设置public很大程度上是为了重写相应接口(override关键词)。状态变量是没有external的。
既然提到了可见性，就多说一句。函数现在必须显示指定可见性，没有默认值，否则编译不能通过。
该状态变量是immutable（不可变的）。关于它的简要介绍在Router合约学习时已经阐述了，这里不使用immutable也是可以的。
factoryV1是一个合约类型的状态变量，factory是地址类型的状态变量。它们可以相互转换，到底使用哪种类型需要根据实际应用场景确定。在Router合约中，需要使用factory地址进行大量计算，并且它重写了一个同名接口，返回类型必须一致，所以为address类型。本例中，除了构造器初始化外，factoryV1只使用了一次并且为外部合约调用，所以使用的是合约类型。
IUniswapV2Router01 immutable router;，定义了router状态变量。注意，它仍然使用的Router1接口，虽然后来Router合约升级到了Router2，但是改动的内容与这里没有关系。

接下来就是构造器，注意在Solidity 0.7.0之后，构造器不再需要public/internal可见性，使用abstract来代表不可构建实例。当然，本合约Solidity版本还是0.6.16。在构造器中实例化了两个状态变量，有部分合约习惯性在这里验证构造器的两个参数不能为零地址，但其实意义不大，几乎没有见过构造器参数输入零地址的情况。

receive() external payable {}这行代码意味该合约可以接受外部发送的ETH。注释中讲到，理想状态下是只接收任意V1版本交易对和路由合约发过来的ETH，但是这样做需要调用V1版本的factory合约，会花费较多gas。因此并没有这样做。

migrate函数，本合约唯一对外接口，也是唯一功能。用来将UniswapV1交易对中的流动性迁移到V2交易对中。它的输入参数分别为：V1交易对中的ERC20代币地址（V1版本交易对中另一种资产为ETH），注入V2交易对的代币数量的下限值，注入V2交易对的ETH数量的下限值，接收V2交易对流动性的地址，最晚交易期限。该函数没有返回值，函数代码具体分析为:

函数的第一行，用来实例化V1版本的交易对，它先调用factoryV1的getExchange方法获取交易对地址，然后再根据此地址实例化。

第二行，获取调用者在V1版本交易对的流动性（V1版本交易对也是ERC20代币，其流动性就是其本身代表的ERC20代币）。V1版本交易对的代码片断为:

name: public(bytes32)                             # Uniswap V1
symbol: public(bytes32)                           # UNI-V1
decimals: public(uint256)                         # 18
totalSupply: public(uint256)                      # total number of UNI in existence
balances: uint256[address]                        # UNI balance of an address
allowances: (uint256[address])[address]           # UNI allowance of one address on another
token: address(ERC20)                             # address of the ERC20 token traded on this contract
1
2
3
4
5
6
7
虽然它是使用Vyper（类Python）语言编写的，仍然可以看出它有name,symbol,decimals,totalSupply,,balances,allowances等ERC20代币的基本属性或接口。

第三行需要将V1交易对的流动性转移到本合约，注意这里因为非直接转移，所以需要事先授权。并且转移后必须返回true值。

第四行将调用V1交易对的removeLiquidity函数，移除调用者在第三行转过来的流动性，得到一种代币和ETH。这里V1版本的removeLiquidity函数的四个参数分别为：移除的流动性数量，得到的最小ETH数量，得到的最小代币数量，最后交易时间。其函数定义为：

@public
def removeLiquidity(amount: uint256, min_eth: uint256(wei), min_tokens: uint256, deadline: timestamp) -> (uint256(wei), uint256):
1
2
这里将得到的ETH及代币最小数量设置为最小值1，将最晚交易时间设置为了最大时间，是为了保证该交易能顺利进行，不受这些条件限制。返回值就是提取的ETH数量和另一种代币的数量。

第五行将对Router1合约进行授权，授权的代币为token，授权的数量就是刚才提取的代币数量amountTokenV1。为什么要授权呢，因为调用Router合约的相应方法需要得到授权，否则无法转移调用者的代币（这里相对Router合约而言，它的调用者就是本合约，所以授权者也是本合约）.

6-13行代码调用Router合约的addLiquidityETH方法进行V2版本的新交易对的资产注入，并得到新交易对的流动性（代币）。该方法的具体学习见序列文章中学习周边合约（二）。需要注意的是，如果注入资产时交易对不存在，则会立即创建它，并将所有的资产全部注入。{value: amountETHV1}语法代表随函数发送的ETH数量，调用时它位于函数名称和参数列表之间。

函数的最后部分将多余的资产返还给最初的调用者。在学习周边合约（二）中提到过，注入资产时理想比率是全部注入（注入资产的比例和交易对中已有资产的比例一致），否则就会有一种有多余的。使用了一个if-else语句来判断是ETH多了还是token多了。

如果是token多了，注意：它的第一步是将token对于本合约的授权额度重置为0，注释中提到是一种良好的习惯，其实也是一种安全防范措施。前段时间的DeFi Saver交易对的用户资产被盗，也有这个授权额度的因素在里面。第二步将多余的代币返回。
如果ETH多了，这里就将ETH退回。注释也讲了，addLiquidityETH会确保所有的资产会被使用（至少会用完其中一种），所以else是安全的，不存在两种资产同时有剩余的情况。
四、实战分析
本合约是UniswapV2自己的从V1交易对迁移到V2交易对的例子。学习完它之后我们再来学习一个从UniswapV2交易对迁移流动性到类似DeFI交易对的例子，下面是SuShiSwap中Migrator.sol的代码片断：

function migrate(IUniswapV2Pair orig) public returns (IUniswapV2Pair) {
    require(msg.sender == chef, "not from master chef");
    require(block.number >= notBeforeBlock, "too early to migrate");
    require(orig.factory() == oldFactory, "not from old factory");
    address token0 = orig.token0();
    address token1 = orig.token1();
    IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
    if (pair == IUniswapV2Pair(address(0))) {
        pair = IUniswapV2Pair(factory.createPair(token0, token1));
    }
    uint256 lp = orig.balanceOf(msg.sender);
    if (lp == 0) return pair;
    desiredLiquidity = lp;
    orig.transferFrom(msg.sender, address(orig), lp);
    orig.burn(address(pair));
    pair.mint(msg.sender);
    desiredLiquidity = uint256(-1);
    return pair;
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
这里不对代码写的好与差做任何评价，只是分析它的代码（个人理解，未必正确）。函数的参数为欲迁移的流动性对应的Uniswapv2交易对，返回参数为新的交易对。虽然这里命名用的是IUniswapV2Pair，但其实旧交易对未必就是UniswapV2交易对，也可以是其它类似DeFi的交易对（甚至是SuShi自己的交易对，不过这样它就必须有两个版本了）。当然，这里肯定就是UniswapV2交易对。

注意：笔者只是很早前大概看了一下SuShi的合约，在写这篇文章时发现它已经将Migartor升级到Migrator2了。瞄了一眼，看上去做了一些改进，但是核心应该没有变。笔者时间有限，就没有再去看新的Migrator2.sol合约了。所以下面的学习仍然以上面的代码为例，有兴趣的读者可以自己去看一下它在github上的最新源码。

函数的前两行用来限定调用者和交易完成时间（不能早于），比较简单。

函数的第三行用来验证输入交易对的factory值为记录的UniswapV2的factoy地址。注意，它这里的oldFactory代表的是UniswapV2的factoy合约。其实这个验证还不完整，还无法区分真的UniswapV2交易对和伪造合约。不过这里调用者受到限制，只有chef有这个可能了。并且就算伪造了，也必须有真实的两种代币资产才行，否则没有意义。

函数的第四行和第五行用来获取UniswapV2交易对的两种资产（ERC20代币）地址。

函数的第六行先是利用SuShi自己的factory合约获取两种资产的交易对地址，然后再实例化。

函数的第7-9行验证如果该实例是在零地址上的实例（代表第6行获取的交易对地址不存在），就先创建该交易对，再利用新创建的交易对地址实例化。当然，这里可以先判断地址不为零地址，如果是零地址的话新创建一个，然后再实例化。

第10行用来获取调用者的UniswapV2交易对的流动性数值。

第11行，如果没有流动性，就不用迁移了，创建了一个新的交易对就结束了。

第12行，desiredLiquidity，这个比较复杂一点。因为SuSchi不同于UniswapV2，不是任何人都可以注入初始流动性的，必须由migrator(也就是本合约)来进行，除非migrator地址值为零地址。这里用来保存欲注入的初始流动性数量（SuShi交易对可以获取到）。SuShi和UniswapV2有些不同，如果注入初始流动性是由migrator完成的，这里的初始流动性的值并不根据UniswapV2公式计算，而是直接沿用了UniswapV2交易对的流动性。

但是由于交易手续费的存在，这里公式计算数值和直接迁移对应的数值并不相等（公式计算的会大一些，因为提取资产时会获得部分手续费）。因为后面流动性再加减都是按比例线性增减的，所以这里并不影响流动性供给，最多算初始流动性计算公式稍微修改了一下。但是因为SuShi交易对是在Uniswap交易对上修改而来，开发团队手续费那一块没有改。如果开发团队手续费打开了，则对开发团队手续费计算可能会有那么一丢丢影响。

第13行，用来将调用者的原UniswapV2的流动性发送至对应的原交易对，准备下一步进行流动性移除来提取资产了。

第14行，调用原交易对的burn方法，注意接收资产的地址直接为新交易对的地址，不需要本合约接收再转移到新交易对。

第15行，调用新交易以的mint方法，用来提供流动性，获得新交易对的流动性代币。（注意，SuShi稍微修改了UniswapV2的交易对，所以它也是一个先转移代币系统）。

第16行，流动性迁移完成后将desiredLiquidity设置为最大值，这也是SuShi的一个保护措施，为最大值时SuShi交易对拒绝注入。相当于一个状态变量实现了两个功能。

最后一行，将新交易对返回。

因为该函数主要是用来处理初始资产注入，所以这里未考虑资产有多余的情况（初始注入不会有多余资产）。

五、结束语
好了，本次迁移合约的学习到此结束了，流动性迁移还是比较简单的。就是先把原流动性提取成相应资产，再转入到类UniswapV2的交易对中，然后再调用新交易对的mint方法进行注入资产得到新流动性。当然，如果资产有剩余的，会返回给调用者。

下一次计划学习UniswapV2周边合约中的一些应用示例。
