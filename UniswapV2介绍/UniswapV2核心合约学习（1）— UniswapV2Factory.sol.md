# UniswapV2核心合约学习（1）— UniswapV2Factory.sol

## 一、UniswapV2合约简要介绍

UniswapV2合约分为核心合约和周边合约，均使用Solidity语言编写。其核心合约实现了UniswapV2的完整功能（创建交易对，流动性供给，交易代币，价格预言机等），但对用户操作不友好；而周边合约是用来让用户更方便的和核心合约交互。

UniswapV2核心合约主要由factory合约（UniswapV2Factory.sol）、交易对模板合约（UniswapV2Pair.sol）及辅助工具库与接口定义等三部分组成。这次先学习UniswapV2Factory合约。

## 二、UniswapV2Factory合约源码一览

其文件名为UniswapV2Factory.sol，其源码为：

```
pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
```

该文件代码很短，只有49行，我们来逐行学习该代码。

## 三、UniswapV2Factory合约源码逐行学习

### 3.1、比较简单的代码部分

1. 代码的第一行，设定使用的Solidity编译器的版本。这里估计是为了更严谨，使用了精确的编译器版本0.5.16，而不是我们常用的>= 0.5.16或者^0.5.16。
2. 代码中的两个import语句分别导入了factory所必须实现的接口合约及交易对模板合约，这个也很简单。
3. contract UniswapV2Factory is IUniswapV2Factory 定义了UniswapV2Factory合约是一个IUniswapV2Factory，它必须实现其所有接口。
4. feeTo这个状态变量主要是用来切换开发团队手续费开关。在UniswapV2中，用户在交易代币时，会被收取交易额的千分之三的手续费分配给所有流动性供给者。如果feeTo不为零地址，则代表开关打开，此时会在手续费中分1/6给开发团队。feeTo设置为零地址（默认值），则开关关闭，不从流动性供给者中分走1/6手续费。它的访问权限设置为public后编译器会默认构建一个同名public函数，正好用来实现IUniswapV2Factory.sol中定义的相关接口。
5. feeToSetter这个状态变量是用来记录谁是feeTo设置者。其读取权限设置为public的主要目的同上。
6. `mapping(address => mapping(address => address)) public getPair;`这个状态变量是一个map(其key为地址类型，其value也是一个map)，它用来记录所有的交易对地址。注意，它的名称为getPair并且为public的，这样的目的也是让默认构建的同名函数来实现相应的接口。注意这行代码中出现了三个address，前两个分别为交易对中两种ERC20代币合约的地址，最后一个是交易对合约本身的地址。
7. allPairs，记录所有交易对地址的数组。虽然交易对址前面已经使用map记录了，但map无法遍历。如果想遍历和索引，必须使用数组。注意它的名称和权限，同样是为了实现接口。
8. `event PairCreated(address indexed token0, address indexed token1, address pair, uint);`交易对被创建时触发的事件，注意参数中的indexed表明该参数可以被监听端（轻客户端）过滤。

9. ```
constructor(address _feeToSetter) public {
    feeToSetter = _feeToSetter;
}
```

构造器，很简单。参数提供了一个初始feeToSetter地址作为feeTo的设置者地址，不过此时feeTo仍然为默认值零地址，开发团队手续费未打开。

10. ```
function allPairsLength() external view returns (uint) {
    return allPairs.length;
}
```

这个函数非常简单，返回所有交易对地址数组的长度，这样在合约外部可以方便使用类似for这样的形式遍历该数组。

11. 我们先跳过createPair函数，该函数最后学习，先看setFeeTo函数：

```
function setFeeTo(address _feeTo) external {
    require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    feeTo = _feeTo;
}
```

这个函数也很简单，用来设置新的feeTo以切换开发团队手续费开关（可以为开发团队接收手续费的地址，也可以为零地址）。注意，该函数首先使用require函数验证了调用者必须为feeTo的设置者feeToSetter，如果不是则会重置整个交易。

12. setFeeToSetter函数

```
function setFeeToSetter(address _feeToSetter) external {
    require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
    feeToSetter = _feeToSetter;
}
```
该函数用来转让feeToSetter。它首先判定调用者必须是原feeToSetter，否则重置整个交易。

但这里有可能存在这么一种情况：当原feeToSetter不小心输错了新的设置者地址_feeToSetter时，设置会立即生效，此时feeToSetter为一个错误的或者陌生的无控制权的地址，无法再通过该函数设置回来。虽然UniswapV2团队不会存在这种疏忽，但是我们自己在使用时，还是有可能发生的。有一种方法可以解决这个问题，就是使用一个中间地址值过渡一下，而新的feeToSetter必须再调用一个接受方法才能真正成为设置者。如果在接受之前发现设置错误，原设置者可以重新设置。具体代码实现可以参考下面的Owned合约的owner转让实现：

```
pragma solidity ^0.4.24;
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"invalid operation");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner,"invalid operation");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
```

### 3.2、createPair函数

该函数顾名思义，是用来创建交易对。之所以将该函数放在最后讲，是因为该函数相对复杂，并且还有一些知识点拓展。下面开始具体分析该函数，函数代码在前面源码部分已经列出了。注意：下文中所说的第几行均不包含空行（跳过空行）。

该函数接受任意两个代币地址为参数，用来创建一个新的交易对合约并返回新合约的地址。注意，它的可见性为external并且没有任何限定，意味着合约外部的任何账号（或者合约）都可以调用该函数来创建一个新的ERC20/ERC20交易对（前提是该ERC20/ERC20交易对并未创建）。

1. 该函数前四行主要是用来进行参数验证，并且同时将代币地址从小到大排序。
    1. 第1行用来验证两种代币的合约地址不能相同，也就交易对必须是两种不同的ERC20代币。
    2. 第2行用来对两种代币的合约地址从小到大排序，因为地址类型底层其实是uint160，所以也是有大小可以排序的。
    3. 第3行用来验证两个地址不能为零地址。为什么只验证了token0呢，因为token1比它大，它不为零地址，token1肯定也就不为零地址。
    4. 第4行用来验证交易对并未创建（不能重复创建相同的交易对）。
2. 该函数第5-10行用来创建交易对合约并初始化。
   1. 第5行用来获取交易对模板合约UniswapV2Pair的创建字节码creationCode。注意，它返回的结果是包含了创建字节码的字节数组，类型为bytes。类似的，还有运行时的字节码runtimeCode。creationCode主要用来在内嵌汇编中自定义合约创建流程，特别是应用于create2操作码中，这里create2是相对于create操作码来讲的。注意该值无法在合约本身或者继承合约中获取，因为这样会导致自循环引用。
   2. 第6行用来计算一个salt。注意，它使用了两个代币地址作为计算源，这就意味着，对于任意交易对，该salt是固定值并且可以线下计算出来。
   3. 第7行中的assembly代表这是一段内嵌汇编代码，Solidity中内嵌汇编语言为Yul语言。在Yul中，使用同名的内置函数来代替直接使用操作码，这样更易读。后面的左括号代表内嵌汇编作用域开始。
   4. 第8行在Yul代码中使用了create2函数（该函数名表明使用了create2操作码）来创建新合约。我们看一下该函数的定义：
--|:--:|--:
create2(v, p, n, s)|C|create new contract with code mem[p…(p+n)) at address keccak256(0xff . this . s . keccak256(mem[p…(p+n))) and send v wei and return the new address, where 0xff is a 1 byte value, this is the current contract’s address as a 20 byte value and s is a big-endian 256-bit value
       1. 第一栏为函数定义，可以看到它有四个参数。
       2. 第二栏代表开始适用的以太坊的版本。C代表Constantinople，也就是从君士坦丁堡版本开始可用。相应的还有F–前沿版本，H–家园版本，B–拜占庭版本，I–伊斯坦布尔版本。在时间轴上，不同版本由旧到新分别为：

       F => H => B => C => I，也就是 前沿 => 家园 => 拜占庭 => 君士坦丁堡 => 伊斯坦布尔 。

       使用该函数时注意对应的以太坊版本。

       1. 第三栏是解释，从中可以看到v代表发送到新合约的eth数量（以wei为单位），p代表代码的起始内存地址，n代表代码的长度，s代表salt。另外它还给出了新合约地址的计算公式。

   5. 第9行是内嵌汇编作用域结束。
   6. 第10行是调用新创建的交易对合约的一个初始化方法，将排序后的代币地址传递过去。为什么要这样做呢，因为使用create2函数创建合约时无法提供构造器参数。

3. 该函数的第11-14行用来记录新创建的交易对地址并触发交易对创建事件。
   1. 第11行和第12行用来将交易对地址记录到map中去。因为：1、A/B交易对同时也是B/A交易对；但在查询交易对时，用户提供的两个代币地址并没有排序，所以需要记录两次。
   2. 第13行将交易对地址记录到数组中去，便于合约外部索引和遍历。
   3. 第14行触发交易对创建事件。
4. create2函数中知识点拓展。
    1. 这里我们先稍微提一下以太坊虚拟机中账号的内存管理。每个账号（包含合约）都有一个内存区域，该内存区域是线性的并且在字节等级上寻址，但是读取限定为256位（32字节）大小，写的时候可以为8位（1字节）或者256位（32字节）大小。
    2. Solidity中内嵌汇编访问本地变量时，如果本地变量是值类型，直接使用该值 ；如果本地变量是引用类型（对内存或者calldata的引用），那么会使用它在内存或者calldata中的地址，而不是值本身。在Solidity中,bytes为动态大小的字节数组，它不是值类型而是引用类型。类似的string也是引用类型。

注意到create2函数调用时使用了类型信息creationCode，结合上面的知识拓展，从该函数代码中我们可以得到：
    
    1. bytecode为内存中包含创建字节码的字节数组，它的类型为bytes，是引用类型。根据上述提到的内存读取限制和内嵌汇编访问本地引用类型的变量的规则，它在内嵌汇编中的实际值为该字节数组的内存地址。函数中首先读取了该内存地址起始的256位（32字节）,它存储了creationCode的长度，具体的获取方法为mload(bytecode)。
    2. 内存中creationCode的实际内容的起始地址为add(bytecode, 32)。为什么会在bytecode上加32呢？因为刚才提到从bytecode开始的32字节存储的是creationCode的长度，从第二个32字节开始才是存的实际creationCode内容。
    3. create2函数解释中的p对应代码中的add(bytecode, 32)，解释中的n对应为mload(bytecode)。

其实以太坊中这样的方式很常见，比如某函数调用的参数为数组时（calldata类型），参数部分编码后，首先第一个单元（32字节）记录的是数组长度，接下来才是数组元素，每个元素（值类型）一个单元（32字节）。

因为使用内嵌汇编会增加阅读难度，所以在Solidity0.6.2版本以后，提供了新语法来实现create2函数的功能，直接在语言级别上支持使用salt创建合约。参见下面示例代码中的合约d的创建过程：

```
pragma solidity >0.6.1 <0.7.0;

contract D {
    uint public x;
    constructor(uint a) public {
        x = a;
    }
}

contract C {
    function createDSalted(bytes32 salt, uint arg) public {
        /// This complicated expression just tells you how the address
        /// can be pre-computed. It is just there for illustration.
        /// You actually only need ``new D{salt: salt}(arg)``.
        address predictedAddress = address(bytes20(keccak256(abi.encodePacked(
            byte(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(D).creationCode,
                arg
            ))
        ))));

        D d = new D{salt: salt}(arg);
        require(address(d) == predictedAddress);
    }
}
```

该代码中通过直接在new的D合约类型后面加上salt选项的方式进行自定义的合约创建，等效使用Yul中的create2函数。注意该示例中predictedAddress的计算方法和create2函数解释中的地址计算方法是一致的。

注意，使用示例中的语法创建新合约还可以提供构造器参数，并不存在create2函数中无法使用构造器参数的问题，因此它也移除了新合约初始化函数的部分需求（初始化在构建器中进行）。但是UniswapV2指定了Solidity的编译器版本为0.5.16，所以无法使用该语法。如果我们自己要使用，需要将编译器版本指定为0.6.2以上，同时需要注意Solidity0.6.2以上的具体某个版本和0.5.16版本有哪些不同并加以修改。
