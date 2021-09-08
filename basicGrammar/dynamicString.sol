pragma solidity ^0.8.7;

contract DynamicString{

    string public name = 'veshen'; //0x76657368656e

    function getLength()
        public
        view
        returns(uint)
    {
        // return name.length; string 不能直接获取length
        /**
            转换为butes 获取长度
         */
        return bytes(name).length;
    }


    function changeName()
        public
        returns(bytes1)
    {
        bytes(name)[0] = 'w';
        // return bytes(name)[0]; 不能直接通过下标获取string里的内容
    }

    function getName()
        public
        view
        returns(bytes memory)
    {
        return bytes(name); //0x76657368656e
    }

}