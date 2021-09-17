# UniswapV3学习（一）

UniswapV3学习（一）
UniswapV3学习（一）NoDelegateCall.sol
NoDelegateCall.sol 源码
代理/实现与委托调用
合约源码分析
测试
结论
UniswapV3学习（一）NoDelegateCall.sol
在UniswapV2学习文章写完之后，很多读者就问我什么时候写V3，彼时V3还未上线，还在不停的commit中，不是最终版本，再加上自己并没有时间，因此并没有去看它。转眼时间来到五月，UniswapV3版本也上线了，笔者也是蹭热度去添加流动性弄了一个NFT玩玩。现在稍微有一点时间，决定回归技术本行，来和大家一起学习UniswapV3版本的智能合约。欢迎大家留言指正或者相互讨论，共同进步共同提高才是最终目的。

在我写这篇文章时，网上已经有人详细了介绍了UniswapV3，这是其中一位作者的系列文章地址：https://liaoph.com/。大家有兴趣的可以先去看一下。当然，我也会去看看作为参考的。

NoDelegateCall.sol 源码
万事开头难，学习一个新的系列合约也没例外，于是我们从简单的开始学起。当然，从核心合约的继承关系来讲，它也是最先学的。我们先看它的源码：

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
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
那个开源协议变更我这里就不讲了，我只讲合约本身的功能。这个合约很简单，只有十行左右的有效代码。那么它是做什么的，在注释中写的很清楚，就是提供一个modifier来阻止某个方法在代理合约的实现合约（注释中的子合约）调用。

代理/实现与委托调用
要想学习这个合约首先得知道Solidity一种常用的实现方式 ---- 代理/实现方式。我们知道，智能合约代码部署到以太坊后就无法更改了，但是这个更改只是指字节码无法更改，并不是该地址的数据无法更改。平常我们也可以通过将关键逻辑放到一个单独的外部合约实现的方式来实现逻辑变更（重新设置一下外部合约地址就好）。但这种方式过于麻烦，有没有全面的可升级合约来更改合约的代码呢？有，这就是利用委托调用实现的代理/实现模式。

那什么是委托调用呢？这里有一个比较简单的示例文章：https://solidity-by-example.org/delegatecall/。它里面有这么一句话：

delegatecall is a low level function similar to call.
When contract A executes delegatecall to contract B, B's code is excuted with contract A's storage, msg.sender and msg.value.
1
2
上面的大意是，当A委托调用B时，调用的是B的代码，引用的却是A的存储数据及msg.sender的msg.value。

合约源码分析
一些基础性的例如编译器版本我就先跳过去了，假定这里读者有一定的Solidity基础。

第6行abstract关键字用来定义这是一个抽象合约，无法直接生成实例（部署）。
第8行及第13行，一个immutable的私有状态变量，用来保存本合约地址。细节是它的注释，注释中提到不可变的状态变量original在合约的初始化代码（这里是在构造器）中被计算，因此它是内嵌入到字节码中，并无法改变。
第16，17行的注释，讲明了因为如果直接使用modifier，该内嵌的字节码会随着modifier被到处复制来复制去，增加gas消耗。因此，使用了一个私有函数，这样调用时只是一个跳转，而不是复制。具体的详情见github上已经关闭的issue。
从该合约的注释中（第4、5行）可以看到，本合约的作用就是提供一个modifier来阻止使用委托调用在子合约中调用某些函数。具体为什么要这么做，笔者现在也不得而知，等以后慢慢弄清楚。

测试
我们来自己写一个测试用例测试该modifier的有效性。
这里UniswapV3本身也提供了测试示例和脚本，大家有兴趣的可以看一下。但我们从实战出发，以平常开发中最常遇到的合约为示例来写。

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
import "@openzeppelin/contracts/proxy/UpgradeableProxy.sol";

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original,"in child contract");
    }

    function getOrigin() internal view returns(address) {
        return original;
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

contract ProxyTest is UpgradeableProxy  {

    constructor(address _implementation) public UpgradeableProxy(_implementation, new bytes(0)) {}

    function implementation() external view returns (address) {
        return _implementation();
    }

    function upgrade(address newImplementation) external {
        _upgradeTo(newImplementation);
    }
}

contract AddressTest is NoDelegateCall  {

    address public test;

    function getAddress() external view returns(address) {
        return address(this);
    }

    function getOriginAddress() external view returns(address) {
        return getOrigin();
    }

    //将其变成非view函数
    function checkAddress() external  noDelegateCall returns(bool) {
        test;
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
此源码中包含三个合约，NoDelegateCall就是原合约，为了方便测试，我们增加一个函数getOrigin来读取original的值，同时在checkNotDelegateCall函数中增加了提示信息。ProxyTest就是我们常用的代理合约，AddressTest就是我们的实现合约。

让我们在truffle部署脚本中一并测试（本地使用ganache作为私有链)。

const AddressTest = artifacts.require("AddressTest");
const ProxyTest = artifacts.require("ProxyTest");

module.exports = async function (deployer) {
  await deployer.deploy(AddressTest);
  let impl = await AddressTest.deployed()
  console.log("impl_address:",impl.address)  // 0x9C4aC2FB0744608B4ccbbB7fedC7a70B4C0180e1
  await deployer.deploy(ProxyTest,impl.address)
  let proxy = await ProxyTest.deployed()
  console.log("proxy_address:",proxy.address) // 0x4a6ff50572092B5aB9673A1D7528F01Be45E73C5
  let instance = await AddressTest.at(proxy.address)
  let result = await instance.getAddress()
  console.log("result:",result)   // 0x4a6ff50572092B5aB9673A1D7528F01Be45E73C5
  let origin = await instance.getOriginAddress()
  console.log("origin:",origin)  //0x9C4aC2FB0744608B4ccbbB7fedC7a70B4C0180e1
  try{
    let tx = await instance.checkAddress()
    console.log(tx.hash)
  }catch(e) {
    console.log(e) //revert in child contract
  }
};
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
从上面的输入中可以看到，实现合约的地址与记录在original中的值是相同的，均为0x9C4aC2FB0744608B4ccbbB7fedC7a70B4C0180e1。
在代理合约中使用委托调用获取address(this)，仍然是代理合约本身的地址。
当我们调用带有noDelegateCall的checkAddress函数时，此时会报错，并给出原因：in child contract，正好是我们在checkNotDelegateCall中设置的提示信息。
从上面可以看出，由于使用了一个immutable变量在合约初始化时便记录了实现合约（子合约）的地址并且内嵌在字节码中，而父合约使用委托代理来调用子合约中定义了noDelegateCall修饰符的函数时，此时address(this)是父合约的地址，因此两者并不相等，无法通过验证，也就起到了阻止作用。

结论
代理/实现是一种常用的模式（通过委托调用实现），而UniswapV3反其道而行之，阻止某些函数被委托调用，肯定有其自身的用意。这个目前笔者并不知晓，暂时只能将答案交给时间了。欢迎有知道答案的读者留言指明，不胜感激。
