//固定长度字节数组
//1个字节 = 8位
/**
    关键字有 bytes1, bytes2 ... bytes32 (以步长1递增)
    byte代表bytes1
    bytes1 == uint8
*/

pragma solidity ^0.8.7;

contract ByteArray{
    /**
        如果声明变量时加了 public 关键字， 函数就会为这个变量自动生成get方法
     */
    bytes1 public num1 = 0x7a;     //0111 1010
    bytes2 num2 = 0x7a68;   //0111 1010 0110 1000
    
    // bytes 内置的属性和方法
    /**
        length 只能读取 不可以修改
     */
    function getLength()
        public
        view
        returns(uint)
    {
        return num1.length;
    }

    bytes1 public a = 0x7a; //0111 1010
    bytes1 public b = 0x68; //0110 1000

    //固定长度字节数组比较操作 < > <= >= != ==

    function bijiao()
        public
        view
        returns(bool)
    {
        return a > b;
    }

    //固定长度字节数组位操作 & | ~ ^ << >> 

    function arrayWei()
        public
        view
        returns(bytes1)
    {
        return ~a;
    }

}