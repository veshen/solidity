// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    modifier 函数修改器 可以被继承

 */

contract modifierTest{

    address public owner;
    uint public num = 0;

    constructor(){
        owner = msg.sender;
    }

    modifier OnlyOwner{
        // require 起一个判断的作用 如果不成立则不执行后面的语句
        require(msg.sender == owner);
        _;
    }

    // 使用方式

    function changeIt(uint _num)
        public
        OnlyOwner
    {
        num = _num;
    }

}