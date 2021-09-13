// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract enumTest{

    //定义枚举 不能为空 不能有汉字 不能加分号
    enum girl{aa,bb,cc}

    girl public dateGirl = girl.aa;

    function getEnum()
        public
        pure
        returns(girl)
    {
        return girl.aa; // -> 0
    }

}