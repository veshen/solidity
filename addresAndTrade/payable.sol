 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;

 /**
    转账 payable
    合约账户也可是可以存储以太币的

    必须使用payable关键字代表可以使用函数进行转账
  */

contract PayableTest{

    function pay()
        payable
        public
    {

    }

    //获取账户上的金额
    //this 就是合约地址
    function getBalance()
        returns(uint)
    {
        return address(this).balance;
    }

}