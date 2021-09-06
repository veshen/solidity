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
    uint numb = 200; //uint  256

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


    //位操作

    uint8 a = 3;
    uint8 b =4;

    /**
        位与
        两个数字之间每一位进行比较 1 1 => 1 同位都是1才返回1
     */
    function weiyu()
        public
        pure
        returns(uint)
    {
        return 3 & 4;
    }
    /**
        位或
        两个数字之间每一位进行比较 1 0 => 1 只要有一位 是1才返回1
     */
    function weihuo()
        public
        pure
        returns(uint)
    {
        return 3 | 4;
    }
    /**
        位反
        位存储的数据0 1互换
     */
    function weifan()
        public
        view
        returns(uint)
    {
        return ~a;
    }
    /**
        位亦或
        两位相等位0 不等为1
     */
    function weiyihuo()
        public
        pure
        returns(uint)
    {
        return 3^4;
    }
    /**
        位左移
        位整体左移动n位
     */
    function weiZuoYi()
        public
        pure
        returns(uint)
    {
        return 3<<1;
    }
    /**
        位右移
        位整体右移动n位
     */
    function weiYuoYi()
        public
        pure
        returns(uint)
    {
        return 3>>1 ;
    }

}