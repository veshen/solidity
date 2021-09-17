# Uniswap合约学习-- Uniswap UNI Token


## 一、UNI Token 介绍

UNI Token 为 Uniswap团队自己发行的以太坊上的ERC20代币，其合约源码在etherscan上已经开源可查。在UniswapV2相关合约学习完之后（学习期间），我们抽空来学习一下它发行的ERC20代币合约。

UNI Token 代币合约并不属于Uniswap交易所的一部分，所以没有把它像以前那样归类到核心合约或者周边合约。但是它的某些实现上，和核心合约中的交易对流动性代币合约的相应实现有些类似。

## 二、合约源码

因为合约源码直接从ethersacn上复制而来，它将所有导入都写在一个源文件里，因此篇幅较长。笔者稍微整理了一下，将SafeMath库放在外面以减少篇幅。修改后的源码为：

```
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

contract Uni {
    /// @notice EIP-20 token name for this token
    string public constant name = "Uniswap";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "UNI";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 1_000_000_000e18; // 1 billion Uni

    /// @notice Address which may mint new tokens
    address public minter;

    /// @notice The timestamp after which minting may occur
    uint public mintingAllowedAfter;

    /// @notice Minimum time between mints
    uint32 public constant minimumTimeBetweenMints = 1 days * 365;

    /// @notice Cap on the percentage of totalSupply that can be minted at each mint
    uint8 public constant mintCap = 2;

    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when the minter address is changed
    event MinterChanged(address minter, address newMinter);

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new Uni token
     * @param account The initial account to grant all the tokens
     * @param minter_ The account with minting ability
     * @param mintingAllowedAfter_ The timestamp after which minting may occur
     */
    constructor(address account, address minter_, uint mintingAllowedAfter_) public {
        require(mintingAllowedAfter_ >= block.timestamp, "Uni::constructor: minting can only begin after deployment");

        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
        minter = minter_;
        emit MinterChanged(address(0), minter);
        mintingAllowedAfter = mintingAllowedAfter_;
    }

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external {
        require(msg.sender == minter, "Uni::setMinter: only the minter can change the minter address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function mint(address dst, uint rawAmount) external {
        require(msg.sender == minter, "Uni::mint: only the minter can mint");
        require(block.timestamp >= mintingAllowedAfter, "Uni::mint: minting not allowed yet");
        require(dst != address(0), "Uni::mint: cannot transfer to the zero address");

        // record the mint
        mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);

        // mint the amount
        uint96 amount = safe96(rawAmount, "Uni::mint: amount exceeds 96 bits");
        require(amount <= SafeMath.div(SafeMath.mul(totalSupply, mintCap), 100), "Uni::mint: exceeded mint cap");
        totalSupply = safe96(SafeMath.add(totalSupply, amount), "Uni::mint: totalSupply exceeds 96 bits");

        // transfer the amount to the recipient
        balances[dst] = add96(balances[dst], amount, "Uni::mint: transfer amount overflows");
        emit Transfer(address(0), dst, amount);

        // move delegates
        _moveDelegates(address(0), delegates[dst], amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Uni::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Uni::permit: amount exceeds 96 bits");
        }

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Uni::permit: invalid signature");
        require(signatory == owner, "Uni::permit: unauthorized");
        require(now <= deadline, "Uni::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Uni::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "Uni::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Uni::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Uni::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Uni::delegateBySig: invalid nonce");
        require(now <= expiry, "Uni::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Uni::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Uni::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Uni::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "Uni::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Uni::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Uni::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Uni::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "Uni::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
```

## 三、源码简介

- 第一行，指定了Solidity版本
- 第二行，指定使用了一个体验功能ABIEncoderV2，到底哪个地方涉及到了体验功能，笔者目前还不清楚。
- 第三行，导入SafeMath库。这个库和UniswapV2周边合约及我们平常使用的SafeMath库稍微有些不同，增加了自定义错误消息的重载函数。下面举一个add函数的代码示例：

```
function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);

    return c;
}
```

- 合约定义头三项为元数据，分别为名称，符号与精度。第四项为发行总量，可以看到为10亿枚。
- 接下来四项从minter到mintCap是增发相关，可以看出最小增发间隔为365天。
- 接下来是allowances授权额度和balances余额，注意它们都为uint96类型，并不是常用的uint256类型。使用Python计算一下（2 ** 96 - 1）/(1e18) 的结果为 79228162514.26434，也就是79亿枚。而当前发行总量是10亿枚，是不会溢出的。
- Checkpoint相关的部分是社区治理（投票）部分，暂时不研究。
- 接下来是三个TYPEHASHP定义。计算方法是一致的，注意在学习UniswapV2中提到了permit使用线下签名消息授权功能，应用于其流动性代币中。这里UNI代币也支持这个功能。同样在学习UniswapV2中也提到了DOMAIN_TYPEHASH。

`mapping (*address* => *uint*) public nonces;` 这一句是在permit函数中防重放的。

- 接下来是五个event，大家从名字也能大致猜出它的含义。
- 构造器constructor。发行所有代币到account地址，并且设置增发者和最早增发时间。
- setMinter函数。更换增发者，这里是直接设置新增发者，不放心怕出错的可以考虑更换/接受模式。多一个接受操作，防止扣操作设置成错误的地址。
- mint函数。增发代币。这里首先验证最早增发时间并更新。然后验证增发数量不能走过原总量的1/50（先乘于2再除于100）。最后进行增发操作（更新相关地址余额和发行总量），同时转移等量委托（投票）权。
- allowance函数，很简单，获取授权额度，基本上所有ERC20代币实现相同 。
- approve函数。授权函数，使用了和UniswapV2交易对流动性代币相似的授权实现，只不过数据大小从uint256变成了uint96（函数内进行了类型转换）。
- permit，使用线下签名消息授权。参考我的另一篇文章UniswapV2核心合约学习（2）——UniswapV2ERC20.sol中的permit函数学习。
- balanceOf函数，很简单，返回某个地址的代币余额。
- transfer函数。也很简单，外部接口，调用内部_transferTokens来实现操作。注意它首先将转移数量转换成了uint96类型。
- transferFrom函数，授权转移函数，也很简单，和UniswapV2交易对中流动性代币的transferFrom实现类似，只不过多了uint256转uint96。
- delegate函数，委托投票，外部接口，直接调用内部函数。一种程序设计模式，使内部接口多处重用。
- delegateBySig使用签名消息委托，同permit函数类似。和permit函数共用nonces。
- getCurrentVotes，获得某地址当前投票数。看实现逻辑使用了检查点来记录不同时刻的投票数，未研究。
- getPriorVotes函数，获得某地址历史投票数。参数分别为查询的地址和历史区块。具体实现逻辑未研究。
- _delegate，委托函数。首先获取旧的委托地址、委托人代币余额，然后更新为新的委托地址。接着触发委托改变事件，最后将相应的委托值（和委托人代币余额数值等额）从旧委托地址转移到新委托地址。
- _transferTokens函数。转移代币资产。这个要点有二处：1、资产的大小为uint96类型，2、是代币转移完成后转同时委托额度。这里SuShi项目在沿用Compound的治理协议时代币转移函数里就少了最后的委托（投票）转移，成为了一个众所周知的bug。
- _moveDelegates，转移委托的具体实现。这里每次转移都写入了检查点，具体逻辑没有研究。
- _writeCheckpoint写入检查点，具体逻辑没有研究。
- 接下来的safe32，safe96，add96及sub96都是实现类似库函数的功能。防止数据上下溢出。
- getChainId函数，使用内嵌汇编获取当前以太坊的区块链ID（区块链ID代表它是主链或者测链或者自定义链）。验证线下签名消息时使用，防止在错误的链上验证。

好了,Uniswap 发行的 UNI Token源码学习就到这结束了。由于主要是学习ERC20代币结构及函数（功能）介绍，所以一些函数的具体实现没有仔细研究。如果读者想参考其中的功能与实现，必须仔细研究清楚。
