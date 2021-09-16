pragma solidity ^0.8.7;


contract testA{
    
    uint _tTotal = 10000;
    // 初始化 rTotal
    uint256 private constant MAX = ~uint256(0);
    // 最大的一个可以整除 _tTotal 的数，这个数字类似于“虚拟的货币总量”
    uint public _rTotal = (MAX - (MAX % _tTotal));
    // 存储用户的虚拟数量
    mapping(address => uint256) public _rOwned;
    address private owner;
    
    
    constructor(){
        owner = msg.sender;
        _rOwned[owner] = _rTotal;
    }
    
    function balanceOf(address account) 
        public 
        view 
        returns (uint256) 
    {
        uint256 currentRate = _rTotal / _tTotal;
        return _rOwned[account] / currentRate;
    }
    function getCurrentRate()
        public
        view
        returns(uint)
    {
        return _rTotal / _tTotal;
    }
    //转账
    function transfer(address from, address to, uint amount) public {
      uint currentRate = _rTotal / _tTotal;
      uint rAmount = amount * currentRate;
      // 3%的分红
      uint rProfit = amount *  currentRate * 3 / 100;
      // 转让人扣除 100%
      _rOwned[from] = _rOwned[from] - rAmount;
      // 接收人收到 97%
      _rOwned[to] = _rOwned[to] + rAmount * 97 / 100;
      
      // 剩下3%扣除总的虚拟货币，这时候所有人的 banlanceOf 函数计算都会按照比例增长
      _rTotal = _rTotal - rProfit;
    }

}