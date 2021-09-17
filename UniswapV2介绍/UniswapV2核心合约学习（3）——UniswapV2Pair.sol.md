记得朋友圈看到过一句话，如果Defi是以太坊的皇冠，那么Uniswap就是这顶皇冠中的明珠。Uniswap目前已经是V2版本，相对V1，它的功能更加全面优化，然而其合约源码却并不复杂。本文为个人学习UniswapV2核心合约源码的系列文章的第三篇。

在上一篇文章中已经学习了UniswapV2核心合约中的第二个源码–合约UniswapV2ERC20.sol的源码。这次我们来学习第三个核心合约–UniswapV2Pair.sol的源码。该合约是交易对合约，在其父合约UniswapV2ERC20的基础上增加了资产交易及流动性供给等功能。

建议读者在开始之前阅读我的另一篇文章：UniswapV2介绍 来对UniswapV2的整体机制有个大致了解，这样更有助于理解源码。

一、合约源码
照例先贴出合约源码，该合约不长，代码只有202行（包括空行），但是相对于前面学习的两个合约，却复杂了许多。

学习该合约需要弄清下面这两个概念：交易对中保存的恒定乘积计算公式中的两种代币的数量ValueA及交易对合约地址拥有的实际代币数量ValueP。这两者通常状态下是相同，但在交易时会发生变化，交易完成后会将ValueA设置为ValueP的值。但某些特殊情况下，它们的值可能是不同的，例如有人由于某种原因误向交易对合约发送了其中一种代币而又没有触发交易。

另外，交易对本身也是一种ERC20合约，它的代币用来代表流动性供给。合约本身不拥有自已的流动性代币，所有代币全部在流动性提供者手里。提供流动性时自动增发代币给提供者，提取流动性时燃烧提供者的代币。

pragma solidity =0.5.16;

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
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
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
145
146
147
148
149
150
151
152
153
154
155
156
157
158
159
160
161
162
163
164
165
166
167
168
169
170
171
172
173
174
175
176
177
178
179
180
181
182
183
184
185
186
187
188
189
190
191
192
193
194
195
196
197
198
199
200
201
二、源码中的简单部分
下面我们分类来学习该合约的源码。注意，本文余下的内容中，阐述的第几行均不包含空行。

pragma solidity =0.5.16; 照例指定确定的Solidity编译器版本。

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
1
2
这两行导入了交易对需要实现的接口和交易对的父合约。

import './libraries/Math.sol';导入一个自定义的Math库，只有两个功能，一个是求两个uint的最小值，另一个是对一个uint进行开方运算。

import './libraries/UQ112x112.sol';导入自定义的数据格式库。在UniswapV2中，价格为两种代币的数量比值，而在Solidity中，对非整数类型支持不好，通常两个无符号整数相除为地板除，会截断。为了提高价格精度，UniswapV2使用uint112来保存交易对中资产的数量，而比值（价格）使用UQ112x112表示，一个代表整数部分，一个代表小数部分。

import './interfaces/IERC20.sol;导入标准ERC20接口，在获取交易对合约资产池的代币数量（余额）时使用。

import './interfaces/IUniswapV2Factory.sol';导入factory合约相关接口，主要是用来获取开发团队手续费地址。

import './interfaces/IUniswapV2Callee.sol';有些第三方合约希望接收到代币后进行其它操作，好比异步执行中的回调函数。这里IUniswapV2Callee约定了第三方合约如果需要执行回调函数必须实现的接口格式。当然了，定义了此接口后还可以进行FlashSwap。

contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {该行定义了本合约实现了IUniswapV2Pair并继承了UniswapV2ERC20，继承一个合约表明它继承了父合约的所有非私有的接口与状态变量。

using SafeMath for uint;和using UQ112x112 for uint224;指定库函数的应用类型。

uint public constant MINIMUM_LIQUIDITY = 10**3;定义了最小流动性。它是最小数值1的1000倍，用来在提供初始流动性时燃烧掉。

bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));用来计算标准ERC20合约中转移代币函数transfer的函数选择器。虽然标准的ERC20合约在转移代币后返回一个成功值，但有些不标准的并没有返回值。在这个合约里统一做了处理，并使用了较低级的call函数代替正常的合约调用。函数选择器用于call函数调用中。

address public factory;,address public token0;,address public token1;用来记录factory合约地址和交易对中两种代币的合约地址。注意它们是public的状态变量，意味着合约外可以直接使用同名函数获取对应的值。

reserve0,reserve1和blockTimestampLast这三个状态变量记录了最新的恒定乘积中两种资产的数量和交易时的区块（创建）时间。

price0CumulativeLast和price1CumulativeLast。记录交易对中两种价格的累计值。

uint public kLast;记录某一时刻恒定乘积中积的值，主要用于开发团队手续费计算。

uint private unlocked = 1;
modifier lock() {
    require(unlocked == 1, 'UniswapV2: LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
}
1
2
3
4
5
6
7
这段代码是用来防重入攻击的，在modifier（函数修饰器）中，_;代表执行被修饰的函数体。所以这里的逻辑很好理解，当函数（外部接口）被外部调用时，unlocked设置为0，函数执行完之后才会重新设置为1。在未执行完之前，这时如果重入该函数，lock修饰器仍然会起作用。这时unlocked仍然为0，无法通过修饰器中的require检查，整个交易会被重置。当然这里也可以不用0和1，也可以使用布尔类型true和false。

getReserves函数，用来获取当前交易对的资产信息及最后交易的区块时间。

_safeTransfer函数，使用call函数进行代币合约transfer的调用（使用了函数选择器）。注意，它检查了返回值（首先必须调用成功，然后无返回值或者返回值为true）。

接下来四个event定义是方便客户端进行各种追踪的。

constructor构造器，很简单，记录factory合约的地址。其实按照Solidity代码规范（建议），这里的构造器和它前面的四个event定义应该放在getReserves函数之前。

initialize函数，进行合约的初始化。在第一篇核心合约源码学习中提到，因为factory合约使用create2函数创建交易对合约，无法向构造器传递参数，所以这里写了一个初始化函数用来记录合约中两种代币的地址。

skim函数，这里从注释就可以看出来，强制交易对合约中两种代币的实际余额和保存的恒定乘积中的资产数量一致（多余的发送给调用者）。注意：任何人都可以调用该函数来获取额外的资产（前提是如果存在多余的资产）。

sync函数，和skim函数刚好相反，强制保存的恒定乘积的资产数量为交易对合约中两种代币的实际余额，用于处理一些特殊情况。通常情况下，交易对中代币余额和保存的恒定乘积中的资产数量是相等的。

三、几个比较复杂的函数
源码中还有几个比较复杂的函数，下面我们分别来学习。

3.1、_mintFee函数
在我的那篇《UniswapV2介绍》中提到，如果开发团队手续费打开后，用户每次交易手续费的1/6会分给开发团队，剩下的5/6才会发给流动性提供者。如果每次用户交易都计算并发送手续费，无疑会增加用户的gas。Uniswap开发团队为了避免这种情况的出现，将开发团队手续费累积起来，在改变流动性时才发送。_mintFee函数就是计算并发送开发团队手续费的。函数的参数为交易对中保存的恒定乘积中的两种代币的数值。

下面我们来看它的代码：

前两行用来获取开发团队手续费地址，并根据该地址是否为零地址来判断开关是否打开。

第三行uint _kLast = kLast;使用一个局部变量记录过去某时刻的恒定乘积中的积的值。注释表明使用局部变量可以减少gas（估计是因为减少了状态变量操作）。

接下来是个if(feeOn)语句，如果手续费开关打开，计算手续费的值（手续费以增发该交易对合约流动性代币的方式体现）。阅读其白皮书，计算公式为：
S m = k 2 − k 1 5 ⋅ k 2 + k 1 ⋅ S 1 S_m = \frac{\sqrt k_2 - \sqrt k_1} {5 \cdot \sqrt k_2 + \sqrt k_1 } \cdot S_1
S 
m
​
 = 
5⋅ 
k
​
  
2
​
 + 
k
​
  
1
​
 
k
​
  
2
​
 − 
k
​
  
1
​
 
​
 ⋅S 
1
​
 

其中 k1为旧的乘积值，即代码中的_klast，k2为新的乘积值，函数中的代码逻辑和计算公式相符。注意到该语句里面还嵌套一个if(_kLast != 0)条件语句，这是为什么呢？

要理解这一点，需要看if(feeOn)的else语句，这里判定如果记录的旧的某时刻的乘积值不为0，则设置为0。这么做的目的是因为手续费开关是可以重复打开关闭的。从后面的mint或者burn函数中，我们可以看到只有手续费打开才会更新这个kLast的值，关闭后是不会更新的。假定打开后再关闭，此时如果不设置kLast为0，那它就是一个无法更新的旧值。然后我们再打开开关，此时kLast是一个很久前的旧值，而不是最近更新的值，而使用旧值会将开关再次打开前的的数据也计算进去（而不是从开关打开的那一时刻开始计算）。

同样这里因为在手续费关闭时将kLast设置为0，if(_kLast != 0)这个条件语句就很好理解了，因为此时代表开关打开，但是最近一次还未更新（开关打开后更新发生在_mint函数之后，此时值为0），所以不能计算。开关打开后只有先更新一次最新的kLast值有了比较才能继续计算。

从这里可以看出，开关打开后的第一次流动性操作只是建立了一个过去时刻的快照值kLast，第二次流动性操作才会有新的快照值，才能使用上面的公式计算手续费。

这里有人可能会有疑惑，我第一次流动性操作和第一次流动性操作的恒定乘积中K的值从代码中是无法看到变化（_mintFee函数发生在更新reserve0和reserve1之前），它们的差额不是0么，哪有什么手续费。是的，如果只是连续的两次流动性操作，k2是和k1是相等的。但是连续两次流动性操作之间是可以存在多次资产（代币）交易的。由于资产交易手续费的存在，虽然是恒定乘积算法，但是这个乘积值K实质上是在慢慢变大的，于是这两个K之间就会有差额了。

3.2、_update函数
这个函数也有几个难点不好理解。注释中的意思为：它用来更新reserves，并且在每个block的第一次调用，更新价格累计值。理解的难点在于理解UniswapV2的数据类型设计、溢出安全函数及价格预言机功能。UniswapV2使用UQ112x112是经过周密考虑的了。第一个使用的地方是使用它保存价格，剩下的32位保存溢出位。第二个使用的地方是它使用uint112保存每种代币的reserve，刚好剩下32位保存当前区块时间（虽然位数会不够，见下面的内容）。

该函数的四个输入参数分别为当前合约两种代币余额及保存的恒定乘积中两种代币的数值。函数功能就是将保存的数值更新为实时代币余额，并同时进行价格累计的计算。

函数内的第一行用来验证余额值不能大于uint112类型的最大值，因为余额是uint256类型的。

函数的第二行解释。因为一个存储插槽为256位，两个代币数量各112位，这样就是224位，只剩下32位没有用了，UniswapV2用它来记录当前的区块时间。因为区块时间是uint类型的，有可能超过uint32的最大值，所以对它取模，这样blockTimestamp的值就永远不会溢出了。但真实的时间值是会超过32位大小的，大约在02/07/2106，见其白皮书。

这里有一点疑惑，使用取模操作和溢出后直接进行Unit32类型转换得到的结果是相同的，不知道为什么要进行一下取模操作。网上有人发起了多个相同的issue，这里是其中一名开发者的回答：

Pretty sure this is just an oversight, given the two are exactly equivalent. Not sure if it makes a difference in terms of gas–may be optimized out.

google翻译了一下：这两个值完全相同，肯定是一个疏忽。不确定是否会对gas产生影响，可能会进行优化。

函数的第三行用来计算当前block时间和上一次block时间的差值。注释中提到已经考虑过溢出了，这个因为笔者不是IT专业出身，从事IT行来时间也比较短，自身基本功不扎实，对二进制、溢出，负数啊，反码啊、补码啊之类的不是很熟悉，因此这里无法完全弄清楚。但是综合这一行和上一行的代码，可以得到一个结论：就是x + delta - x = delta 在x + delta 溢出的时候仍然成立（未溢出时显然是成立的）。

这里我举一个非常牵强的示例（未必正确），例子中x和delta均为uint8类型：

从uit8(-1) = 255 我们可以得到第一点结论：一个负数x在uint中会被视为正数，它的值为 x + 255 + 1(按位取反+1，按位取反就是+255，如果有溢出位，溢出位超过了数据长度，因此可以忽略)。

从平常应用中我们可以得到第二点结论：如果x + delta溢出（不是为负数），那么它的真实值为 x + delta - 255 - 1 。

将上面两点综合起来，会得到 （x + delta） - x = x + delta - 255 - 1 - x = delta - 255 - 1。它肯定是一个负数，按照负数在uint中的计算规则，它会 + 255 + 1，所以进一步得到：（x + delta） - x = delta - 255 - 1 + 255 + 1 = delta。所以在x + delta 溢出情况下，x + delta - x = delta仍然成立。

从这个合约的实际应用来看，x就是上一次的区块时间，x + delta就是当前区块时间，delta就是时间间隔。只不过数据类型从uint8变成了uint32。因为区块时间被转换成了uint32类型，而取模操作和溢出后低位数值是相同的，所以这里就算新的区块时间在取模转换后小于旧的区块时间（相当于溢出了），这个时间间隔也是正确的。

函数的第四行是一个if语句，如果是同一个区块的第二笔及以后交易，timeElapsed就会为0，此时就不会计算价格累计值。

函数的第五行及第六行是计算两种价格的累积值，注释// * never overflows, and + overflow is desired提到了两层意思：

永远不会溢出。个人认为是指：价格是uint224，timeElapsed是uint32，一个uint32乘于一个uint224显然是永远不会溢出uint256的。

考虑到了+溢出，白皮书讲到这个方法是溢出安全的。这里个人认为需要从价格预言机的真实应用方式来理解。因为代码只是记录了价格累计值，预言机真实价格计算取得是区间平均值，也就是(P2-P1)/(T2-T1)，或者为deltaP/deltaT。这里P1和P2分别代表某个区块的价格累计值，T2和T1分别代表区块时间，deltaP与deltaT分别代表价格变化值与时间变化值。此价格计算公式我们可以进一步写成(P1 + deltaP - P1)/(T1 + deltaT - T1)。从这里看出什么门道没有？我们在分析第三行代码时已经得出结论：在x + delta 溢出情况下，x + delta - x = delta仍然成立。也就是说，不管是分子的价格溢出了还是分母的区块时间溢出了，deltaP与deltaT总是正确的，所以deltaP/deltaT(平均价格）也总是正确的，也就是该区间价格也总是正确的。从这里可以看到价格累计设计非常巧妙，既防止了在同一区块内操纵价格（见介绍文章），又是溢出安全的。这里的个人理解基于上面个人结论：x + delta 溢出情况下，x + delta - x = delta仍然成立。如果上面结论错误，这里个人理解也会错误，切记。

这里有细心的读者可能会发现，如果x + delta数据太大，不只溢出一次怎么办？这里白皮书给出了一个建议，就是每个周期（232-1秒）内至少进行一次价格检查。因为从累积公式可以得出，一个周期内（232-1秒）最多只会溢出一次（当然也可能不会溢出）。

函数的第8，9，10行用来更新交易对中恒定乘积中的reserve的值，同时更新block时间为当前block时间（这样一个区块内价格只会累积计算一次）。

函数的最后一行触发了同步事件，用于客户端追踪。

3.3、mint函数
该函数的注释表明这个低等级函数应该从一个合约调用，并且需要执行重要的安全检查。在系列文章最开始已经讲过，核心合约对用户不友好，需要通过周边合约来间接交互。因此，从周边合约调用也刚好符合这个要求。

mint函数的主要功能就是在用户提供流动性时（提供一定比例的两种ERC20代币到交易对）增发流动性代币给提供者。注意流动性代币也是一种ERC20代币，是可以交易的，由此还衍生了一些其它类型的DeFi。函数的参数为接收流动性代币的地址，函数的返回值为增加的流动性数值。

函数的第一行用来用来获取当前交易对的reverse，注意它的元组赋值的语法。当左边个数小于右边时，它使用类似javascript的语法，而不是类似golang的那种使用一个"_“代替未使用变量。但是在函数参数中，如果有未使用变量，是可以使用”_"来代替未使用的变量名的，否则有些编译器会给出未使用变量的警告。
函数的2-5行用来获取当前合约注入的两种资产数量。注意UniswapV2采用了先转移代币，再调用合约的交易方式。因此，除了FlashSwap外，所有需要支付的代币都必须事先转移到交易对中。但是这样就不方便外部账号进行此类操作，一般是通过周边合约进行类似操作。
函数的第6行发送开发团队手续费（如果相应开关打开的了话）
第七行uint _totalSupply = totalSupply;使用一个局部变量来保存已经发行流动性代币的总量。这样可以少操作状态变量，节省gas。注意，注释中提到了因为_mintFee函数可能更新已发行流动性代币的数量（具体在if (liquidity > 0) _mint(feeTo, liquidity);这一行代码），所以必须在它之后赋值。
接下来的if-else语句根据是否为初次提供流动性作了不同处理。如果是初次，其计算方法为恒定乘积公式中积的平方根，同时还需要燃烧掉部分最初始的流动性，具体数值为MINIMUM_LIQUIDITY。这样做的原因见我的介绍文章或者查阅其白皮书及官方文档。如果不是初次提供，则会根据已有流动性按比例增发。由于注入了两种代币，所以会有两个计算公式，每种代币按比例计算一次增发的流动性数量，取其中的最小值。
接下来的require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');语句是讲增发的流动性必须大于0，等于0相当于无增发，白做无用功。
_mint(to, liquidity);这一句代码增发新的流动性给接收者。
_update(balance0, balance1, _reserve0, _reserve1);更新当前保存的恒定乘积中两种资产的值。
if (feeOn) kLast = uint(reserve0).mul(reserve1);，如果手续费打开了，更新最近一次的乘积值。该值不随平常的代币交易更新，仅用来流动性供给时计算开发团队手续费。可以参考一下_mintFee函数的解释。
最后一行emit Mint(msg.sender, amount0, amount1);，很简单，触发一个增发事件让客户端追踪。
3.4、burn函数
该函数刚好和mint函数功能相反。mint函数是通过同时注入两种资产来获取流动性（以增发流动性代币的形式表现）；而burn函数是通过燃烧流动性代币的形式来提取相应的两种资产，从而减小该交易对的流动性。

函数的参数为代币接收者的地址，返回值是提取的两种代币数量。注意，它需要事先将流动性代币转回交易对中。

函数的前三行用来获取交易对的reverse及代币地址，并保存在局部变量中，注释中提到也是为了节省gas。

第4-5行用来获取交易对合约地址拥有两种代币的实际数量。

第6行用来获取事先转入的流动性的数值。正常情况下，交易对合约是没有任何流动性代币的。虽然它是发币合约，所有的流动性代币全在流动性提供者手里。

第7行计算手续费，见mint函数。虽然提取资产并不涉及到流动性增发，但是这里还是要计算并发送手续费。如果仅在注入资产时计算并发送手续费，用户提取资产时就会计算不准确。

uint _totalSupply = totalSupply;作用同mint函数。

amount0 = liquidity.mul(balance0) / _totalSupply;
amount1 = liquidity.mul(balance1) / _totalSupply;
1
2
这里按比例计算提取资产。

require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');需要提取资产数量大于0，也就是有最小燃烧值需求。

_burn(address(this), liquidity);将用户事先转入的流动性燃烧掉。因为此时流动性代币已经转移到交易对，所以燃烧的地址为address(this)。

_safeTransfer(_token0, to, amount0);
_safeTransfer(_token1, to, amount1);
1
2
用来将相应数量的ERC20代币发送给接收者。

balance0 = IERC20(_token0).balanceOf(address(this));
balance1 = IERC20(_token1).balanceOf(address(this));
1
2
这里重新获取了交易对合约地址拥有的两种代币的余额，那么这个值可不可以通过原余额减去发送的数量来得到呢？如果能这里为什么还是通过代币合约来获取呢？这里我的个人理解为：通过代币合约获取会更准确一些。因为我们不知道这两种ERC20代币的合约源码，有可能有些代币合约对余额的计算方式有特殊处理（比如增加一个动态变化的系数等），使用原数量减去发送的数量未必就是正确的余额。

_update(balance0, balance1, _reserve0, _reserve1);更新当前保存的恒定乘积中两种资产的值，同mint函数。

if (feeOn) kLast = uint(reserve0).mul(reserve1);，更新KLast的值，同mint函数。

emit Burn(*msg*.sender, amount0, amount1, to);很简单，触发一个燃烧事件让客户端追踪。

3.5、swap函数
该函数实现交易对中资产（ERC20代币）交易的功能，也就两种ERC20代币互相买卖，而多个交易对可以组成一个交易链。
该函数定义为：

function swap(uint amount0Out, uint amonun1Out, address to, bytes calldata data) external lock {

它有四个参数，分别为购买的token0的数量，购买的token1的数量，接收者地址，接收后执行回调时的传递数据。

它和V1版本不同的是函数参数中不再有出售资产的数量了，因为出售的资产（ERC20代币）需要事先转入到交易对中，通过比较交易对中的代币余额和恒定乘积中的reserve来计算得到。

它最后有一个lock修饰符，是防重入的。因为在UniswapV1中，假定所有代币的回调函数不会有重入风险。但是在实际应用中发现，部分非ERC20代币打破了这一假定。因此在V2版本中，对必要的函数都做了防重入处理。

函数的第一行用来校验输入参数不能为0，不作无意义的事。

第二行用来获取交易对的reverse。

第三行校验购买的数量必须小于reverse，否则没有那么多代币卖。根据恒定乘积计算公式，等于也是不行的，那样输入就是无穷大。

4-5行定义了两个局部变量，它们来保存当前交易对的两种代币余额

第6行和第15行组成一对{}，它是一个特殊的语法，注释说是用来避免堆栈过深错误。为什么会有堆栈过深错误呢，因为以太坊虚拟机（EVM）访问堆栈时最多只能访问16个插槽，当访问的插槽数超过16个时在编译时就会产生stack too deep errors。这个错误产生的原因也比较复杂（比如函数内参数、返回参数及局部变量过多，或者引用过深等），和部分操作码也有一定关联。但是这里应该是函数内局部变量过多引起的，UniswapV2使用下面的语法来避免这个问题 ：

uint var1;
{
    (uint varA, uint varB) = getVars();
    var1 = varA + varB;
}

// now use var1
1
2
3
4
5
6
7
该方法的原理未知，网上能搜索到的文章都是说受Uniswap启发，可以使用scope变量的方式解决局部变量过多的问题。

这里有一篇文章，简要讲述了堆栈过深错误产生的原因和五种解决方法，希望大家有空时可以看一下，对自己编写智能合约还是有帮助的 =>>> Stack Too Deep

7-9行使用两个局部变量记录token地址并验证接收者地址不能为token地址。

10-11行先行转出购买资产。

12行的意思是如果参数data不为空，那么执行调用合约的uniswapV2Call回调函数并将data传递过去，普通交易调用时这个data为空。

13-14行用来获取交易对合约地址两种代币的余额并保存在4-5行定义的变量中。

16-17行用来计算实际转移进来的代币数量。

18行对上面计算出来的数量进行验证，你必须转入某种资产（大于0）才能交易成另一种资产。

19-23行又是个scope variables，用来防止stack too deep errors。

20-22行是进行最终的恒定乘积验证，V2版本的验证公式为：(x1 - 0.003 * xin) * (y1 - 0.003 * yin) >= x0 * y0，注意这里的x1和y1不是reserve,而是balance，而x0和y0是reserve。xin和yin为注入的资产数量，因此要扣除千分之三的交易手续费。这个公式的意思为新的恒定乘积的积必须大于旧的值，因为此时reserve未更新，所以使用的是balance，验证完成后reserve会更新为balance。xin和yin中任意一个为0，就变成V1版本的验证公式了。

24行是更新恒定乘积中的资产值reserve为balance。

25行是触发一个事件便于客户端进行追踪

对于该函数，有几点额外说明：

从函数参数中来看，只有amount0Out和amount0Out1，它们是想要获得的代币数量，直观上未看到对应哪种代币。因为A/B交易对同时也是B/A交易对，那么要怎样区分哪种代币是多少呢？为了让用户能够区分到底是指定哪种代币和有个固定顺序，UniswapV2在交易对内部对地址从小到大做了排序。token0就是较小代币地址，reserve0同样就是交易对池子中较小地址代币的数量，因此函数的输入参数amount0Out对应了拟获取的较小地址代币的数量，这一点可以从if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);这行代码中得到进一步验证。（因为amount0Out如果不代表token0这种代币的数量，是不会调用token0的transfer函数的）。

函数是先将购买的代币发送出去，然后如果data不为空的话，会调用接收者合约的回调函数，完成之后才会再计算转入的另一种代币数量。很明显，这是一个先花后支付设计。为什么这样设计呢？这里是方便大家进行套利（套利的同时可以让Uniswap交易对中的价格更接近于外部价格）。假定该交易对为一个A/B交易对，你可以先得到购买的代币B而不支付任何代币A，然后利用购买的代币B在别的交易所中进行交易，得到一定数量的代币A，然后再将支付的代币A还给交易对。如果此时A还有剩余，那么你就获得了利润。然而这种套利并不需要你提前拥有A或者B这两种资产，属于无成本套利（不过需要支付gas费用）。当然个人账号是没有代码的，所以也就没有回调函数，只有使用智能合约进行这种无成本套利（正常手动套利不受影响，不过需要拥有对应的代币）。

从代码上看并无直接支付交易手续费的操作，但是实际上在验证恒定乘积时，由于手续费的存在，用户付出的代币数量Xin是高于交易前根据恒定乘积公式计算出来的数量Xp的。由于手续费是千分之三，可以得到：
X i n = 1000 997 ⋅ X p Xin = \frac {1000} {997} \cdot Xp
Xin= 
997
1000
​
 ⋅Xp
