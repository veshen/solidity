pragma solidity ^0.4.0;

contract BooleanTest{
    /**
        bool 不分配变量默认为false
     */
    bool _a;
    int num1 = 100;
    int num2 = 200;

    function getBool() returns(bool) {
        return _a;
    }

    function getBool2() returns(bool) {
        //！ 取反
        return !_a;
    }

    /**
        判断
     */

    function panduan() returns(bool){
        return num1 === num2;
    }

    function panduan2() returns(bool){
        return num1 !== num2;
    }

    /**
        && || !
     */
    
}