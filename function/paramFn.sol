// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    函数的命名参数
 */

contract funcParam{

    uint public num;
    string public name;

    function setParam(uint _num, string memory _name)
        public
    {
        num = _num;
        name = _name;
    }

    function test()
        public
    {
        setParam(10,'veshen');
    }

    function test2()
        public
    {
        setParam({
            _num: 100,
            _name: 'veshen'
        });
    }

}