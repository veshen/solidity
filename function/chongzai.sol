// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    函数
    function (<paramter types>) 
        { private | internal | external public }
        [ pure | constant | view | payable ]
        [ returns(<return types>) ]
    
    函数重载
    1. 函数名字相同
    2. 函数参数不同 类型 或者 数量
    调用时会匹配参数符合的函数
 */

contract chongzai{

    function fn(uint a)
        public
    {

    }

    function fn(string memory b)
        public
    {
        
    }

    function test(){
        //调用时会匹配参数符合的函数
        fn('veshen');
    }

}