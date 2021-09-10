// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    继承
    public 可以被继承
    internal 可以被继承 可以在合约内部调用，不能被外部调用
    private 私有属性 不可以被继承 只能被当前合约独立使用
    external 函数用的 可以被继承 ，可以在合约外部调用 不能在当前合约内部调用 或者this.xxx()
 */

contract grandFather{
    uint public gudong = 200;
}

contract testF{
    grandFather g = new grandFather();
    function getGudong()
        public
        view
        returns(uint)
    { 
        return g.gudong;
    }
}

contract father is grandFather{
    uint num = 10000;
    function dahan()
        public
    {

    }
}

contract son is father{

    function getNum()
        public
        returns(uint)
    {
        return num;
    }

    function test()
        public
    {
        dahan();
    }

    function genGudong()
        public
        view
        returns(uint)
    {
        return gudong;
    }

}