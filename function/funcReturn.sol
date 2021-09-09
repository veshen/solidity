// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    函数的返回值
    函数返回值可以命名
 */

contract returnTest{

    function test()
        public
        returns(uint num)
    {
        // num = 100; 可以直接写返回值

        return 100;  //return 优先级高于直接写返回值
    }

    function test2()
        public
        returns(uint a, string memory name)
    {

    }

}