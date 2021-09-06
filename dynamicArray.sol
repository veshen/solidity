// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    动态字节数组
 */

contract DynamicByte{

    bytes public name = new bytes(2);

    function InitName()
        public
    {
        name[0] = 0x7a;
        name[1] = 0x68;
    }

    function getLength()
        public
        view
        returns(uint)
    {
        return name.length;
    }

    function changeName()
        public
    {
        name[0] = 0x88;
    }

    /**
        动态字节数组长度修改
        solidity 0.4.0可以修改
        0.8.7不可以修改
     */

    // function changeLength(uint len)
    //     public
    // {
    //     name.length = len;
    // }

    function pushTest()
        public
    {
        name.push(0x99);
    }

}