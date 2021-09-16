/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
    EIP 中定义的 ERC20 标准的接口。
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     返回存在的代币数量。
     发行代币的总量，可以通过这个函数来获取。所有智能合约发行的代币总量是一定的，
     totalSupply必须设置初始值。如果不设置初始值，这个代币发行就说明有问题。
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     返回 `account` 拥有的代币数量。 
     输入地址，可以获取该地址代币的余额。
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *      将 `amount` 代币从调用者的帐户移动到 `recipient`。
     * Returns a boolean value indicating whether the operation succeeded.
     *返回一个布尔值，指示操作是否成功。
     * Emits a {Transfer} event. 发出 {Transfer} 事件。
     调用transfer函数将自己的token转账给recipient地址，amount为转账个数
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *通过 {transferFrom} 返回允许 `spender` 代表 `owner` 花费的剩余代币数量。 默认情况下为零。
     * This value changes when {approve} or {transferFrom} are called.
     当 {approve} 或 {transferFrom} 被调用时，这个值会改变。
     返回_spender还能提取token的个数。
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *      将 `amount` 设置为 `spender` 对调用者令牌的允许。
     * Returns a boolean value indicating whether the operation succeeded.
     *返回一个布尔值，指示操作是否成功。

     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     重要提示：请注意，使用此方法更改配额会带来风险，即有人可能会通过不幸的交易顺序同时使用旧配额和新配额。 
     缓解这种竞争条件的一种可能解决方案是首先将支出者的津贴减少到 0，然后再设置所需的值：
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     批准_spender账户从自己的账户转移_value个token。可以分多次转移。
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *使用津贴机制将“amount”代币从“sender”移动到“recipient”。
      然后从来电者的津贴中扣除`amount`。
     * Returns a boolean value indicating whether the operation succeeded.
     *返回一个布尔值，指示操作是否成功。
     * Emits a {Transfer} event.
     与approve搭配使用，approve批准之后，调用transferFrom函数来转移token。
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *当 `value` 代币从一个帐户（`from`）移动到另一个帐户（`to`）时发出。
     * Note that `value` may be zero.
     当成功转移token时，一定要触发Transfer事件
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     当通过调用 {approve} 设置“所有者”的“支出者”津贴时发出。 `value` 是新的津贴。
     当调用approval函数成功时，一定要触发Approval事件
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/Context.sol
pragma solidity >=0.6.0 <0.8.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *提供有关当前执行上下文的信息，包括事务的发送者及其数据。 
 虽然这些通常可通过 msg.sender 和 msg.data 获得，
 但不应以这种直接方式访问它们，因为在处理 GSN 元交易时，
 发送和支付执行的帐户可能不是实际的发送者（就 一个应用程序有关）。
 * This contract is only required for intermediate, library-like contracts.
 只有中间的、类似library的contracts才需要这个contracts。

 abstract 抽象合约 
当合约中至少有一个功能没有实现时，需要将合约标记为抽象。即使所有功能都已实现，合约也可能被标记为抽象。

这可以通过使用关键字来完成，如下例所示。请注意，此合约需要定义为abstract，因为定义了函数，
但没有提供实现（没有给出实现主体）。abstractutterance(){ }
@see https://docs.soliditylang.org/en/v0.8.7/contracts.html?highlight=abstract#abstract-contracts
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: contracts/IUniswapV2Router01.sol

// IUniswapV2Router01 通常用于在 Uniswap 中创建令牌对。

// 令牌需要允许令牌对一些特权操作，例如重新平衡流动性。
pragma solidity >=0.6.2;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: contracts/IUniswapV2Router02.sol
pragma solidity >=0.6.2;
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: contracts/IUniswapV2Factory.sol
pragma solidity >=0.5.0;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: contracts/IUniswapV2Pair.sol
pragma solidity >=0.5.0;
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
// File: contracts/Ownable.sol
pragma solidity ^0.7.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *提供基本访问控制机制的合约模块，其中有一个帐户（所有者）可以被授予对特定功能的独占访问权限。
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *默认情况下，所有者帐户将是部署合约的帐户。 这可以稍后通过 {transferOwnership} 更改。
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 该模块通过继承使用。 它将提供修饰符`onlyOwner`，它可以应用于您的函数以限制它们对所有者的使用。
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     初始化合约，将部署者设置为初始所有者。
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     返回当前所有者的地址。
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     如果由所有者以外的任何帐户调用，则抛出。
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: 调用者不是所有者");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *离开没有所有者的合同。 将无法再调用 `onlyOwner` 函数。 只能由当前所有者调用。
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     放弃所有权将使合同没有所有者，从而删除任何仅对所有者可用的功能。
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     将合同的所有权转移到新帐户（`newOwner`）。
      只能由当前所有者调用。
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: contracts/SafeMath.sol
pragma solidity ^0.7.0;
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *返回两个无符号整数的相加，带有溢出标志。
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *返回两个无符号整数的减法，带有溢出标志。
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *返回两个无符号整数的乘积，带有溢出标志。
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        //Gas 优化：这比要求 'a' 不为零要便宜，但如果 'b' 也被测试，好处就会丢失。
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *返回两个无符号整数的除法，除以零标志。
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *返回除以零标志的两个无符号整数相除的余数。
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *返回两个无符号整数的相加，溢出时恢复
     * Counterpart to Solidity's `+` operator.
     *与 Solidity 的 `+` 运算符相对应。
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *返回两个无符号整数的减法，在溢出时恢复（当结果为负时）。
     * Counterpart to Solidity's `-` operator.
     *与 Solidity 的 `-` 运算符相对应。
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *返回两个无符号整数的乘积，在溢出时恢复。
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: 乘法溢出 multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *返回两个无符号整数的整数除法，在除以零时恢复。 结果向零四舍五入。
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *与 Solidity 的 `/` 操作符相对应。 注意：这个函数使用了一个 `revert` 操作码（它使剩余的 gas 保持不变），
     而 Solidity 使用一个无效的操作码来恢复（消耗所有剩余的 gas）。
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *返回两个无符号整数相除的余数。 （无符号整数模），除以零时恢复。
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *与 Solidity 的 `%` 操作符相对应。 这个函数使用一个 `revert` 操作码（保持剩余的 gas 不变），
     而 Solidity 使用无效的操作码来恢复（消耗所有剩余的 gas）。
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *返回两个无符号整数的减法，在溢出时返回自定义消息（当结果为负时）。
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *注意：此函数已被弃用，因为它需要为错误消息不必要地分配内存。 出于自定义还原原因，请使用 {trySub}。
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *返回两个无符号整数的整数除法，在除以零时返回自定义消息。 结果向零四舍五入。
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *注意：此函数已被弃用，因为它需要为错误消息不必要地分配内存。 出于自定义还原原因，请使用 {tryDiv}。
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *与 Solidity 的 `/` 操作符相对应。 注意：这个函数使用了一个 `revert` 操作码（它使剩余的 gas 保持不变），
     而 Solidity 使用一个无效的操作码来恢复（消耗所有剩余的 gas）。
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *返回两个无符号整数相除的余数。 （无符号整数模），除以零时返回自定义消息。
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *注意：此函数已被弃用，因为它需要为错误消息不必要地分配内存。 出于自定义还原原因，请使用 {tryMod}。
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *与 Solidity 的 `%` 操作符相对应。 这个函数使用一个 `revert` 操作码（保持剩余的 gas 不变），
     而 Solidity 使用无效的操作码来恢复（消耗所有剩余的 gas）。
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/BDR.sol
pragma solidity ^0.7.6;

contract BDR is IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool private swapping;
    // reflect
    string public name;
    string public symbol;
    uint8 public decimals;
    // 排除在外 啥呢？
    address[] private _excluded;
    uint256 private _tFeeTotal;
    // 存储用户的虚拟数量
    mapping(address => uint256) public _rOwned;
    mapping(address => uint256) public _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    //最大值
    uint256 private constant MAX = ~uint256(0);
    // _tTotal 真正的发行量（比如发行了 1w 枚币，精度为0，_tTotal = 10000）
    uint256 private constant _tTotal = 1000000000000000 * (10**18);
    // 最大的一个可以整除 _tTotal 的数，这个数字类似于“虚拟的货币总量”
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    //最大买入交易金额
    uint256 public maxBuyTranscationAmount = 2000000000000 * (10**18);
    //最大卖出交易金额
    uint256 public maxSellTransactionAmount = 2000000000000 * (10**18);
    //交换代币数量
    uint256 public swapTokensAtAmount = 1000000000000 * (10**18);
    uint256 public _maxWalletToken = 3000000000000 * (10**18);
    uint256 public lpLockTime;
    address public burnAddress;
    address payable public wallet1Address;
    address payable public wallet2Address;
    // made private, team will be paid in BNB
    //私有化，团队将以 BNB 支付
    address private wallet1TokenAddressForFee;
    address private wallet2TokenAddressForFee;
    // Fees
    uint256 public wallet1Fee;
    uint256 public wallet2Fee;
    uint256 public tokenRewardsFee;
    uint256 public liquidityFee;
    uint256 public totalAdminFees;
    // Previous Fees
    uint256 public prevWallet1Fee;
    uint256 public prevWallet2Fee;
    uint256 public prevTokenRewardsFee;
    uint256 public prevLiquidityFee;
    uint256 public prevTotalAdminFees;
    
    uint256 public sellFeeIncreaseFactor = 100;
    address public presaleAddress = address(0);
    // timestamp for when the token can be traded freely on PCS
    //代币可以在 PCS 上自由交易的时间戳 PCS 中央银行运营的支付清算和结算系统
    uint256 public tradingEnabledTimestamp = 1629274107;
    // blacklisted from all transfers
    //从所有转移中列入黑名单
    mapping (address => bool) public _isBlacklisted;

    // exlcude from fees and max transaction amount
    //应该就是一个不需要支付手续费 没有最大额度转账限制的账户mapping
    mapping (address => bool) public _isExcludedFromFees;

    mapping (address => bool) public _isExcludedMaxSellTransactionAmount;
    // addresses that can make transfers before presale is over
    //可以在预售结束前进行转账的地址
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    //自动做市商配对的商店地址。 任何转移*至*这些地址 可能会受到最大转账金额的限制
    mapping (address => bool) public automatedMarketMakerPairs;
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BurnWalletUpdated(address indexed newBurnWallet, address indexed oldBurnWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);

    constructor() public {

        uint256 _tokenRewardsFee = 3;
        uint256 _liquidityFee = 5;
        uint256 _wallet1Fee = 4;
        uint256 _wallet2Fee = 3;
        uint256 _lpLockTime = 1629274107;
        
        name = "Baby Doge Rocket";
        symbol = "BDR";
        decimals = 18;
        tokenRewardsFee = _tokenRewardsFee;
        liquidityFee = _liquidityFee;
        wallet1Fee = _wallet1Fee;
        wallet2Fee = _wallet2Fee;
        totalAdminFees = _liquidityFee + _wallet1Fee + _wallet2Fee;
        lpLockTime = _lpLockTime;

        burnAddress = address(0xdead);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
         //为这个新令牌创建一个 uniswap 对
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        // 排除支付费用或拥有最大交易金额
        excludeFromFees(burnAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        //owner 可以在交易启用前转账
        canTransferBeforeTradingIsEnabled[owner()] = true;


        //把发行量和虚拟货币总量全都给  owner
        _rOwned[owner()] = _rTotal;
        _tOwned[owner()] = _tTotal;
        // 当成功转移token时，一定要触发Transfer事件
        emit Transfer(address(0), owner(), _tTotal);
    }

    // receive BNB
    receive() external payable {}
    // reflect 发行代币的总量
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    //获取用户余额
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromFees[account]) return _tOwned[account];
        // _rOwned[account] 地址对应的发行量
        return tokenFromReflection(_rOwned[account]);
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        // 查询地址账户中的发行量 必须小于总发行量
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        //返回发行量 / 一个比例
        return rAmount.div(currentRate);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    function updatMaxBuyTxAmount(uint256 _newAmountNoDecimals) external onlyOwner {
        maxBuyTranscationAmount = _newAmountNoDecimals * (10 **decimals);
    }    
    function updatMaxSellTxAmount(uint256 _newAmountNoDecimals) external onlyOwner {
        maxSellTransactionAmount = _newAmountNoDecimals * (10 **decimals);
    }
    function swapAndLiquifyOwner(uint256 _tokens) external onlyOwner {
        swapAndLiquify(_tokens);
    }
    function updatelpLockTime (uint256 newTimeInEpoch) external onlyOwner {
        lpLockTime = newTimeInEpoch;
    }       
    function withdrawLPTokens () external onlyOwner{
        require(block.timestamp > lpLockTime, 'Wait for LP locktime to expire!');
        uint256 currentBalance = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).transfer(owner(),currentBalance);
        
    }      
    function updateTradingEnabledTime (uint256 newTimeInEpoch) external onlyOwner {
        tradingEnabledTimestamp = newTimeInEpoch;
    }     
    function updateSellIncreaseFee (uint256 newFeeWholeNumber) external onlyOwner {
        sellFeeIncreaseFactor = newFeeWholeNumber;
    }
    function updateMaxWalletAmount(uint256 newAmountNoDecimials) external onlyOwner {
        _maxWalletToken = newAmountNoDecimials * (10**decimals);
    }     
    function updateSwapAtAmount(uint256 newAmountNoDecimials) external onlyOwner {
        swapTokensAtAmount = newAmountNoDecimials * (10**decimals);
    } 
    function updateWallet1Address(address payable newAddress) external onlyOwner {
        wallet1Address = newAddress;
        excludeFromFees(newAddress, true);  
    }    
    function updateWallet2Address(address payable newAddress) external onlyOwner {
        wallet2Address = newAddress;
        excludeFromFees(newAddress, true);  

    }         
    function updateFees(uint256 _tokenRewardsFee, uint256 _liquidityFee, uint256 _wallet1Fee, uint256 _wallet2Fee) external onlyOwner {
        tokenRewardsFee = _tokenRewardsFee;
        liquidityFee = _liquidityFee;
        wallet1Fee = _wallet1Fee;
        wallet2Fee = _wallet2Fee;
        totalAdminFees = _liquidityFee + wallet1Fee + wallet2Fee;
    }
    function whitelistDxSale(address _presaleAddress, address _routerAddress) external onlyOwner {
        presaleAddress = _presaleAddress;
        canTransferBeforeTradingIsEnabled[presaleAddress] = true;
        excludeFromFees(_presaleAddress, true);
        canTransferBeforeTradingIsEnabled[_routerAddress] = true;
        excludeFromFees(_routerAddress, true);
    }
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "BDR: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    function excludeFromReward(address account) internal {
        // require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude Uniswap router.');
        //require(!_isExcludedFromFees[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromFees[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) internal {
        //require(_isExcludedFromFees[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromFees[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        if(excluded){
            excludeFromReward(account);
        }else{
            includeInReward(account);
        }
        //emit ExcludeFromFees(account, excluded);
    }       
    function blacklistAddress(address account, bool excluded) public onlyOwner {
        _isBlacklisted[account] = excluded;
    }    
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "BDR: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BDR: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }
    function removeAllFee()
        private 
    {
        if(tokenRewardsFee == 0 && liquidityFee == 0) return;    
        prevWallet1Fee = wallet1Fee;
        prevWallet2Fee = wallet2Fee;
        prevTokenRewardsFee = tokenRewardsFee;
        prevLiquidityFee = liquidityFee;
        prevTotalAdminFees = totalAdminFees;
        wallet1Fee = 0;
        wallet2Fee = 0;
        tokenRewardsFee = 0;
        liquidityFee = 0;
        totalAdminFees = 0;
    }
    function restoreAllFee() private {
        wallet1Fee = prevWallet1Fee;
        wallet2Fee = prevWallet2Fee;
        tokenRewardsFee = prevTokenRewardsFee;
        liquidityFee = prevLiquidityFee;
        totalAdminFees = prevTotalAdminFees;
    }
    //转账方法
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        //黑名单地址无法转移
        require(!_isBlacklisted[from], "Blacklisted address cannot transfer!");
        //黑名单地址无法转移
        require(!_isBlacklisted[to], "Blacklisted address cannot transfer!");
        //零地址不可以转出
        require(from != address(0), "ERC20: transfer to the zero address");
        //零地址不可以收款
        require(to != address(0), "ERC20: transfer to the zero address");
        
            if (
            from != owner() && //转出者不是owner
            to != owner() && // 收款者不是owner
            to != address(0) && // 收款者不是零地址
            to != address(0xdead) && //收款者不是 ？？
            !automatedMarketMakerPairs[to] &&  //转入转出者不是 自动做市商配对的商店地址
            automatedMarketMakerPairs[from]
        ) {
            require(
                amount <= maxBuyTranscationAmount, //转账金额必须小于等于 最大买入交易金额
                "Transfer amount exceeds the maxTxAmount."
            );
            //收款地址余额
            uint256 contractBalanceRecipient = balanceOf(to);
            require(
                contractBalanceRecipient + amount <= _maxWalletToken,
                "Exceeds maximum wallet token amount."
                //收款之后的总余额必须小于等于 _maxWalletToken
            );
        }
        //是否已经开启交易
        bool tradingIsEnabled = getTradingIsEnabled();

        if(!tradingIsEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "BDR: 在启用交易之前，此帐户无法发送代币");
        }
        
        if(amount == 0) {
            return;
        }

        if( 
            !swapping &&
            tradingIsEnabled && //已经开启交易
            automatedMarketMakerPairs[to] &&  //转入转出者不是 自动做市商配对的商店地址
            // sells only by detecting transfer to automated market maker pair
            // 仅通过检测到自动做市商对的转移进行销售
            from != address(uniswapV2Router) && 
            //router -> pair is removing liquidity which shouldn't have max
            //路由器 -> 货币对正在消除不应具有最大值的流动性
            !_isExcludedFromFees[to]  //收款账户不是免税账户
            //no max for those excluded from fees
            //不收取费用的人没有最高限额
        ) {
            //转账金额超过 maxSellTransactionAmount
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount."); 
        }
        //合约代币余额
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            tradingIsEnabled && //已经开启交易
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] && //转入转出者是 自动做市商配对的商店地址
            from != burnAddress &&
            to != burnAddress
        ) {
            swapping = true;
            swapAndLiquify(swapTokensAtAmount);
            swapping = false;
        }

        //转账费用
        bool takeFee = tradingIsEnabled && !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        // 如果任何帐户属于 _isExcludedFromFee 帐户，则取消费用
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
/*
        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);

            // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }

            amount = amount.sub(fees);

            //super._transfer(from, address(this), fees);
            _tokenTransfer(from,address(this),fees,takeFee);
        }*/

       // super._transfer(from, to, amount);
       //真正开始转账， 
       _tokenTransfer(from,to,amount,takeFee);

    }
    
    //this method is responsible for taking all fee, if takeFee is true
    // 此方法负责收取所有费用，如果 takeFee 为true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee(); // 如果takeFee 为false 清空所有费用
        
        if (_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
            //如果转账者是免税账户 收款者不是免税账户
            _transferFromExcluded(sender, recipient, amount);
            
        } else if (!_isExcludedFromFees[sender] && _isExcludedFromFees[recipient]) {
            //如果转账者不是免税账户 收款者是免税账户
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
             //如果转账者收款者都不是免税账户
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromFees[sender] && _isExcludedFromFees[recipient]) {
            //如果转账者收款者都是免税账户
            _transferBothExcluded(sender, recipient, amount);
        } else {
            //这里默认使用 都不是免税账户的方式
            _transferStandard(sender, recipient, amount);
        }
        
        //如果是免税账户转账 则转账完成后 恢复所有费用
        if(!takeFee) 
            restoreAllFee();
    }
     //如果转账者收款者都不是免税账户
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFees(tAdminFees);
        _reflectFee(rRewardFee, tRewardFee);
        // 当成功转移token时，一定要触发Transfer事件
        emit Transfer(sender, recipient, tTransferAmount);
    }
    // 收取费用
    function _takeFees(uint256 tAdminFees) private {
        uint256 currentRate =  _getRate();
        uint256 rAdminFees = tAdminFees.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rAdminFees);
        if(_isExcludedFromFees[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tAdminFees);
    }
    //如果转账者不是免税账户 收款者是免税账户
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getValues(tAmount);
        //转账者扣除转账金额
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // 收款者添加收款金额
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeFees(tAdminFees);
        _reflectFee(rRewardFee, tRewardFee);
        // 当成功转移token时，一定要触发Transfer事件
        emit Transfer(sender, recipient, tTransferAmount);
    }

    //转账者是免税账户 收款者不是免税账户
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getValues(tAmount);
        // 从转账者账户扣除转账金额
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // 从收款者账户增加 到账金额
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        //收取管理费
        _takeFees(tAdminFees);
        //分红费用？
        _reflectFee(rRewardFee, tRewardFee);
        // 当成功转移token时，一定要触发Transfer事件
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeFees(tAdminFees);
       _reflectFee(rRewardFee, tRewardFee);
       // 当成功转移token时，一定要触发Transfer事件
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    /**
    * @param tAmount 转账金额
    * @return rAmount 转账金额
    * @return rTransferAmount 实际转账金额
    * @return rRewardFee 分红金额
    * @return tTransferAmount 实际转账金额
    * @return tRewardFee 分红金额
    * @return tAdminFees 管理费
     */
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        // t 的 实际转账金额， 转账分红， 总管理费
        (uint256 tTransferAmount, uint256 tRewardFee, uint256 tAdminFees) = _getTValues(tAmount); //返回 实际转账金额， 转账分红， 总管理费
        // r的 转账金额 实际转账金额 转账分红
        (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardFee) = _getRValues(tAmount, tRewardFee,tAdminFees, _getRate());

        return (rAmount, rTransferAmount, rRewardFee, tTransferAmount, tRewardFee, tAdminFees);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        //转账分红 = 转账金额 * 费率 / 100
        uint256 tRewardFee = calculateTokenRewardFee(tAmount);
        // 总管理费 = 转账金额 * totalAdminFees / 100
        uint256 tAdminFees = calculateAdminFees(tAmount);
        //实际转账金额 = 转账金额 - 转账分红 - 总管理费
        uint256 tTransferAmount = tAmount.sub(tRewardFee).sub(tAdminFees);
        //返回 实际转账金额， 转账分红， 总管理费
        return (tTransferAmount, tRewardFee, tAdminFees);
    }
    //计算转账分红
    function calculateTokenRewardFee(uint256 _amount) private view returns (uint256) {
        //转账金额 * 费率 / 100
        return _amount.mul(tokenRewardsFee).div(10**2);
    }
    //总管理费
    function calculateAdminFees(uint256 _amount) private view returns (uint256) {
        //转账金额 * totalAdminFees / 100
        return _amount.mul(totalAdminFees).div(10**2);
    }
    /**
     * @param tAmount 转账金额
     * @param tRewardFee 转账分红
     * @param tAdminFees 管理费
     * @param currentRate 虚拟货币总量 / 真实货币总量 得到的一个比例，除以这个比例即可拿到真实的余额。
     *
     * @return rAmount  转账金额 = 转账金额 * currentRate
     * @return rRewardFee  转账分红 = 转账分红 * currentRate
     * @return rAdminFees  管理费 = 管理费 * currentRate
     * @return rTransferAmount  r转账金额 = 转账金额 - 转账分红 - 管理费
     *
     */
    function _getRValues(uint256 tAmount, uint256 tRewardFee, uint256 tAdminFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rRewardFee = tRewardFee.mul(currentRate);
        uint256 rAdminFees = tAdminFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rRewardFee).sub(rAdminFees);
        return (rAmount, rTransferAmount, rRewardFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        //总发行量
        uint256 rSupply = _rTotal;
        //虚拟货币总量
        uint256 tSupply = _tTotal; 

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    

    function swapHandler(address payable walletAddress, address tokenAddressForFee, uint256 feeBalance, uint256 feePortion) internal {
        if(tokenAddressForFee != address(0)){
            swapEthForTokens(feeBalance, tokenAddressForFee, walletAddress);
            //_transfer(address(this), burnAddress, wallet1feePortion);
            //emit Transfer(address(this), burnAddress, wallet1feePortion);
        }else{
            (bool sent,) = walletAddress.call{value: feeBalance}("");
            if(sent){
                //_transfer(address(this), burnAddress, wallet1feePortion);
                //emit Transfer(address(this), burnAddress, wallet1feePortion);
            } else {
                addLiquidity(feePortion, feeBalance);
            }
        }   
    }
    
    function portionCalculator(uint256 _walletFee, uint256 _otherHalf, uint256 _newBalance) internal returns (uint256,uint256){
        // calculate the portions of the liquidity to add to wallet fee
        // 计算要添加到钱包费用的流动性部分
        uint256 walletfeeBalance = _newBalance.div(totalAdminFees).mul(_walletFee);
        uint256 walletfeePortion = _otherHalf.div(totalAdminFees).mul(_walletFee);        
        return (walletfeeBalance,walletfeePortion);
    }    

    function feeBalanceHandler(uint256 _wallet1Fee, uint256 _wallet2Fee, uint256 _otherHalf, uint256 _newBalance) internal returns(uint256, uint256){
        (uint256 wallet1feeBalance,uint256 wallet1feePortion) = portionCalculator(_wallet1Fee,_otherHalf,_newBalance);
        (uint256 wallet2feeBalance,uint256 wallet2feePortion) = portionCalculator(_wallet2Fee,_otherHalf,_newBalance);
        uint256 walletTotalBalance = wallet1feeBalance + wallet2feeBalance;
        uint256 walletTotalPortion = wallet1feePortion + wallet2feePortion;
        allWalletSwapOne(wallet1feeBalance,wallet1feePortion,wallet2feeBalance,wallet2feePortion);
        return(walletTotalBalance,walletTotalPortion);
    }
    function finalCalculator(uint256 _wallet1Fee, uint256 _wallet2Fee, uint256 _otherHalf, uint256 _newBalance) internal{
        (uint256 walletTotalBalance, uint256 walletTotalPortion) = feeBalanceHandler(_wallet1Fee,_wallet2Fee,_otherHalf,_newBalance);
        uint256 finalBalance = _newBalance - walletTotalBalance;
        uint256 finalHalf = _otherHalf - walletTotalPortion;
        // add liquidity to uniswap 为 Uniswap 增加流动性
        // 为 Uniswap 增加流动性为 Uniswap 增加流动性
        addLiquidity(finalHalf, finalBalance);
    }    
    function allWalletSwapOne(uint256 wallet1feeBalance, uint256 wallet1feePortion,uint256 wallet2feeBalance, uint256 wallet2feePortion) internal{
        // added to manage receiving bnb
        // 添加管理接收bnb
        swapHandler(wallet1Address, wallet1TokenAddressForFee, wallet1feeBalance, wallet1feePortion);         
        swapHandler(wallet2Address, wallet2TokenAddressForFee, wallet2feeBalance, wallet2feePortion);    
    }    
    function swapAndLiquify(uint256 tokens) internal  {
        // split the contract balance into halves
        // 将合约余额分成两半
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        // 获取合约当前的 ETH 余额。
        // 这样我们就可以准确地捕捉到 ETH 的数量
        // 掉期创建，而不是使流动性事件包括任何 ETH
        // 已经手动发送到合约
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH 将代币换成 ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered 这会在触发交换+液化时破坏 ETH -> HATE 交换
        // how much ETH did we just swap into? 我们刚换了多少 ETH？
        uint256 newBalance = address(this).balance.sub(initialBalance);
        // calculate the portions of the liquidity to add to wallet1fee
        //计算要添加到 wallet1fee 的流动性部分
        // calculate finals 计算决赛
        finalCalculator(wallet1Fee,wallet2Fee,otherHalf,newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function swapEthForTokens(uint256 ethAmount, address tokenAddress, address receiver) private {
        // generate the uniswap pair path of weth -> token
        // 生成 weth -> token 的 Uniswap 对路径
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;
        // make the swap 进行交换
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of ETH 接受任何数量的 ETH
            path,
            receiver,
            block.timestamp
        );
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        // 生成 token -> weth 的 Uniswap 对路径
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public {
        // approve token transfer to cover all possible scenarios
        // 批准令牌转移以涵盖所有可能的情况
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity 增加流动性
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable 滑点是不可避免的
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        ); 
    }
}