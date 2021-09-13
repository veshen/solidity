// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract structTest{

    // struct 代表一个结构体 或者说一个对象

    //定义结构体 
    struct student{
        uint grade;
        string name;
    }

    struct student2{
        uint grade;
        mapping(uint => string) map;
    }


    /**
        结构体的初始化
     */
    function init()
        public
        pure
        returns(uint,string memory)
    {
        student memory s = student(100,'veshen');
        return(s.grade,s.name);
    }
    function init2()
        public
        pure
        returns(uint,string memory)
    {
        student memory s = student({
            grade:100,
            name:'veshen'
        });
        return(s.grade,s.name);
    }


    struct Request{
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalsCount;
        mapping(address => bool) approvals;
    }
        
    uint numRequests;
    mapping (uint => Request) requests;
    
    function createRequest (string memory description, uint value, address recipient) 
        public
    {
        Request storage r = requests[numRequests++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalsCount = 0;
            
    }

}