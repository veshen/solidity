pragma solidity ^0.4.0;

contract math{
    /**
        定义整型
        1. int
        2. uint
        区别 int 可正可负数
        unit 非负数类型
     */

    int numa = 100; //int256 == int 
    uint numb = 200; //uint 256

    function add(uint a,uint b) 
        public
        pure 
        returns(uint)
    {
        return a+b;
    }

    function jian(uint a,uint b)
        public
        pure
        returns(uint)
    {
        return a - b;
    }

    function cheng(uint a, uint b)
        public
        pure
        returns(uint)
    {
        return a * b;
    }

    function chu(uint a, uint b)
        public
        pure
        returns(uint)
    {
        return a / b;
    }

    function yu(uint a, uint b)
        public
        pure
        returns(uint)
    {
        return a % b;
    }

    function pingfang(uint a, uint b)
        public
        pure
        returns(uint)
    {
        return a**b;
    }


}