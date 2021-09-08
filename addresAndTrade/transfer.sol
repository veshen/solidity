 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;

 /**
    如何在外部账户与外部账户之间转账
  */

contract transferTest{
    
    function transferBalance()
        public
        payable
    {
        //接收的账户地址
        address account = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

        payable(account).transfer(msg.value);
        
    }

    function getBalance(address account)
        public
        returns(uint)
    {
        return account.balance;
    }
    
    function transfer2()
        public
        payable
    {
        payable(this).transfer(msg.value);
    }
    
    fallback()
        external
        payable
    {
        
    }
   
}