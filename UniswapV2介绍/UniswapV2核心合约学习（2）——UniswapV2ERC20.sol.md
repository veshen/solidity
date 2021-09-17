记得朋友圈看到过一句话，如果Defi是以太坊的皇冠，那么Uniswap就是这顶皇冠中的明珠。Uniswap目前已经是V2版本，相对V1，它的功能更加全面优化，然而其合约源码却并不复杂。本文为个人学习UniswapV2核心合约源码的系列文章的第二篇。

在上一篇文章中已经学习了UniswapV2核心合约中的第一个源码–合约UniswapV2Factory.sol的源码。这次我们来学第二个核心合约–UniswapV2ERC20.sol的源码。它是交易对合约的父合约，主要实现了ERC20代币功能并增加了对线下签名消息进行授权的支持。它除了标准的ERC20接口外还有自己的接口，因此取名为UniswapV2ERC20。

建议读者在开始学习之前阅读我的另一篇文章：UniswapV2介绍 来对UniswapV2的整体机制有个大致了解，这样更有助于理解源码。

一、合约源码
照例先贴出合约源码，该合约也不长，代码只有94行（包括空行）：

pragma solidity =0.5.16;

import './interfaces/IUniswapV2ERC20.sol';
import './libraries/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant name = 'Uniswap V2';
    string public constant symbol = 'UNI-V2';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
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
二、源码逐行学习
下面我们按照从上到下的顺序，逐行学习该合约源代码，注意，本文余下的内容中，阐述的第几行均不包含空行。

pragma solidity =0.5.16; 照例指定确定的使用的Solidity版本。

import './interfaces/IUniswapV2ERC20.sol'; import './libraries/SafeMath.sol';这两行导入了该合约必须实现的接口IUniswapV2ERC20.sol和一个防溢出的数学工具库SafeMath。一个合约实现的接口代表了它的基本功能；防溢出数学工具库应用很常见，主要是因为数值是可以无限大的，但是存储位数是有限的。例如最大256位，因此最大的无符号整数就是是2**256-1。再大就会溢出，这时就会得到预期外的结果。另外，因为在Solidity中，应用最多的是无符号整数，如果减法得到了负数，根据二进制的表示法，结果会被认为成另一个无符号整数。在早期的智能合约中，存在溢出漏洞或者得到负值而遭受损失的情况。当前编写的智能合约一般都会防范这种问题的发生，使用SafeMath工具库是最常见的预防手段。注意，该库里只有加、减和乘三种计算，没有除法。因为除法不会有溢出；如果被零除，Solidity语言本身会报错重置整个交易，不需要额外处理。

contract UniswapV2ERC20 is IUniswapV2ERC20 { 这一行定义了该合约必须实现导入的IUniswapV2ERC20接口。该接口是由标准ERC20接口加上自定义的线下签名消息支持接口组成，所以UniswapV2ERC20也是一个ERC20代币合约。最后一个花括号是作用域开始。

using SafeMath for uint;代表在uint256(uint是它的同名)类型上使用SafeMath库。Solidity中库函数在指定调用实例时（例如本例中的.sub等)和Rust语言中的结构体的方法类似，实例自动作为库函数中的第一个参数。

string public constant name = 'Uniswap V2';
string public constant symbol = 'UNI-V2';
uint8 public constant decimals = 18;
1
2
3
这三行代码定义了ERC20代币的三个对外状态变量（代币元数据）：名称，符号和精度。这里的精度就是小数点位数。注意，由于该合约为交易对合约的父合约，而交易对合约是可以创建无数个的，所以这无数个交易对合约中的ERC20代币的名称、符号和精度都一样。我们平常在交易所中看到的只是ERC20代币的符号，从这里可以看出，符号是可以重复的，并不是唯一确定的。代币之间根本区别是合约地址，这个是唯一的，不同的地址就是不同的代币，哪怕合约代码完全一样。

uint public totalSupply 记录代币发行总量的状态变量。为什么是访问权限是public的呢？这个在学习系列（一）中已经讲过了。主要是利用编译器的自动构造同名函数功能来实现相应接口。

mapping(address => uint) public balanceOf;用一个map记录每个地址的代币余额。

mapping(address => mapping(address => uint)) public allowance;用来记录每个地址的授权分布，用于非直接转移代币（例如调用第三方合约来转移）。这个概念初学者不好理解，为什么要授权后才能转移代币呢？这里打个比方，代币合约就相当于银行，你直接去银行转账（代币）是不需要授权的。但是如果你使用微信充值，将银行卡里的钱充值到微信钱包，微信必须得到你的授权（包括额度），这样微信才能在你的授权额度范围内转移你银行卡内的钱。如果没有授权机制而可以直接转钱的话，微信就可能把你的银行卡悄无声息的掏空了。同样，如果你访问第三方合约（非代币合约），第三方合约没有得到你的授权就无法转移你的代币。否则，遇到个恶意合约，一下就把你所有的代币都偷走了。

bytes32 public DOMAIN_SEPARATOR;用来在不同Dapp之间区分相同结构和内容的签名消息，该值也有助于用户辨识哪些为信任的Dapp，具体可见eip-712提案。

bytes32 public constant PERMIT_TYPEHASH这一行代码根据事先约定使用permit函数的部分定义计算哈希值，重建消息签名时使用。

mapping(address => uint) public nonces;记录合约中每个地址使用链下签名消息交易的数量，用来防止重放攻击。

接下来两个event是ERC20标准中的两个事件定义，方便客户端进行一些追踪。

constructor构造器。该构造器只做了一件事，计算DOMAIN_SEPARATOR的值。根据EIP-712的介绍，该值通过domainSeparator = hashStruct(eip712Domain)计算。这其中eip712Domain是一个名为EIP712Domain的 结构，它可以有以下一个或者多个字段：

string name 可读的签名域的名称，例如Dapp的名称，在本例中为代币名称。
string version当前签名域的版本，本例中为"1"。
uint256 chainId。当前链的ID，注意因为Solidity不支持直接获取该值，所以使用了内嵌汇编来获取。
address verifyingContract验证合约的地址，在本例中就是本合约地址了。
bytes32 salt用来消除歧义的salt，它可以用来作为DOMAIN_SEPARATOR的最后措施。在本例中对'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'进行keccak256运算后得到的哈希值。
注意：结构体本身无法直接进行hash运算，所以构造器中先进行了转换，hashStruct就是指将结构体转换并计算最终hash的过程。

_mint函数，进行代币增发，注意它是internal函数，所以外部是无法调用的。

_burn函数，进行代币燃烧，同样它也是internal函数。

_approve函数，进行授权操作，注意它是private函数，意味着只能在本合约内直接调用。不过，在子合约中可以通过一个内部或者公共的函数进行间接调用。

_transfer函数，转移代币操作，注意也是一个private函数。

approve函数，注意它是external（外部）函数，用户通常进行授权操作的外部调用接口。

transfer函数，同上，用户转移代币操作的外部调用接口。

transferFrom代币授权转移函数，它是一个外部函数，主要是由第三方合约来调用。注意它的实现中（UniswapV2的实现）作了一个假定，如果你的授权额度为最大值（几乎用不完，相当于永久授权），为了减小操作步数和gas，调用时授权余额是不扣除相应的转移代币数量的。这里如果没有授权（授权额度为0），那么会怎样呢？库函数.sub(value)调用时无法通过SafeMath的require检查，会导致整个交易会被重置。所以如果没有授权，第三方合约是无法转移你的代币的，你不用担心你的资产被别的合约随便偷走。

permit使用线下签名消息进行授权操作。为什么会有使用线下签名然后再线上验证操作这种方式呢？首先线下签名不需要花费任何gas，然后任何其它账号或者智能合约可以验证这个签名后的消息，然后再进行相应的操作（这一步可能是需要花费gas的，签名本身是不花费gas的）。线下签名还有一个好处是减少以太坊上交易的数量，UniswapV2中使用线下签名消息主要是为了消除代币授权转移时对授权交易的需求。

三、知识拓展
3.1、链下签名消息
链下签名消息相关知识可以参考Solidity官方文档中的Solidity by Example下的Micropayment Channel示例。根据应用场景的不同，签名的消息包含不同的内容，但一般都要包含一个防重放攻击的元素。通常使用和以太坊交易本身相同的技巧，即使用一个nonce记录账号进行交易的数量，智能合约检查该nonce以确保签名消息不被多次使用。本例中签名消息的内容包括：[PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline]。从代码nonces[owner]++中 可以看到，每调用一次permit，相应地址的nonce就会加1，这样再使用原来的签名消息就无法再通过验证了（重建的签名消息不正确了），也就防止了重放攻击。

在以太坊中，在ECDSA签名原有的r和s的基础上加了一个v，使用它们可以验证签名消息的账号。Solidity中有一个内置的函数ecrecover来获取消息的签名地址，它使用签名消息和r,s,v作为参数。

使用链下签名消息的常用流程是在首先链上根据输入参数重建整个签名消息，然后将重建的签名消息和输入的签名消息进行处理及比较对照，来进行相关判定和验证输入信息未受到篡改。

链下签名计算实质上是模拟的是Solidity中的keccak256及abi.encodePacked函数，因此本合约中消息签名的计算方式为bytes32 digest = keccak256（这行及接下来的代码。计算后得到一个hash值digest，利用这个值和函数参数中的，r,s,v，使用ecrecover函数就可以得到消息签名者的地址。将这个对址和owner相对比，就可以验证该消息是否由owner签名的（显而易见每个账号只能对本地址进行授权操作）。注意：签名内容包含了spender和value，如果签名内容的任意值做了更改，使用原来的r,s,v是无法通过验证的。

查看了一下UniswapV2的前端，它使用了web3-react中的eth_signTypedData_v4方法来计算签名消息中的r,s,v的，最终传递给了permit函数作为参数。这里V1版本前端直接使用的是Javascript + React，V2版本前端使用的是TypeScript + React。

3.2、EIP-712
该提案是用来增强链下签名消息在链上的可用性的。具体内容参见github上的EIP地址：https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md，它同时提供了一个测试示例Example.sol，本合约中DOMAIN_SEPARATOR的计算方法和示例中是一致的。因为原生的签名消息对用户不太友好，用户无法从中获取更多信息，使用EIP-712第一可以让用户了解消息签名的大致描述，第二可以让用户辨识哪些是信任的Dapp，哪些是高风险的Dapp，从而不随便签名消息让自己遭受损失（比如一个恶意Dapp进行伪装等）。

3.3、为什么存在permit函数
现在我们来弄明白为什么存丰permit函数。UniswapV2的核心合约虽然功能完整，但对用户不友好，用户需要借助它的周边合约才能和核心合约交互。但是在涉及到流动性供给时，比如用户减少流动性，此时用户需要将自己的流动性代币（一种ERC20代币）燃烧掉。由于用户调用的是周边合约，周边合约未经授权是无法进行燃烧操作的（ 上面提到过）。此时，如果按照常规操作，用户需要首先调用交易对合约对周边合约进行授权，再调用周边合约进行燃烧，这个过程实质上是调用两个不同合约的两个交易（无法合并到一个交易中），它分成了两步，用户需要交易两次才能完成。

使用线下消息签名后，可以减少其中一个交易，将所有操作放在一个交易里执行，确保了交易的原子性。在周边合约里，减小流动性来提取资产时，周边合约在一个函数内先调用交易对的permit函数进行授权，接着再进行转移流动性代币到交易对合约，提取代币等操作。所有操作都在周边合约的同一个函数中进行，达成了交易的原子性和对用户的友好性。

因此permit函数存在并且执行了授权操作的原因：

第三方合约在进行ERC20代币转移时（代币交易），用户首先需要调用代币合约进行授权（授权交易），然后才能调用第三方合约进行转移。这样整个过程将构成分阶段的两个交易，用户必须交易两次，失去了交易的原子性。使用线下消息签名线上验证的方式可以消除对授权交易的需求，permit就是进行线上验证并同时执行授权的函数。

当然如果用户会操作的话，也可以手动授权，不使用permit函数相关的周边合约接口进行交易。

3.4、代币元数据
什么叫代币元数据，指的是代币名称，符号（简写）和精度。这三种元数据虽然存在于标准的ERC20协议中，必须得到实现，但是对于代币转移本身来讲却是没有任何作用或者意义的（代币转移函数transfer和transferFrom并未使用到它们）。它们属于对外展示的属性，所以在ERC1155协议中，不管是同质代币还是非同质代币（例如ERC721藏品）已经取消了这三种元数据，设法将它们放到了链下（不过放到链下就意味着需要一个额外的存储媒介）。然而当前钱包对ERC1155的支持并不太友好，并且ERC1155代币统一处理各种资产，无法同时满足多种场景需求。ERC1155提案虽然已变成Final状态两年了，始终未得到大规模应用。

这次的学习就到此结束了。由于个人能力有限，难免有理解错误或者不正确的地方，还请大家多多留言指正。
————————————————
