pragma solidity ^0.8.0;

import "./PToken_Server.sol";

interface iPerformancePool {
    function restartPerformance() external;

    function getPerformanceWithAddress() external;
}

contract CITYSocialServer is iPerformancePool {
    struct RegisterStruct {
        bool isRegister;
        address upAddress;
    }

    struct AwardStruct {
        uint8 RemainingAward;
        mapping(address => uint8) downAwardMap;
    }

    mapping(address => RegisterStruct) DownLinkUpMap;

    mapping(address => AwardStruct) UpAddressDistributionAwardMap;

    mapping(address => uint8) downAddressAwardMap;

    mapping(address => uint64) PerformanceValueMap;

    uint256 _decimals;

    address public owner;

    address pTokenContractAddress;

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor() {
        _decimals = 100;
        owner = msg.sender;
    }

    function initPTokenServer(address _pTokenContractAddress) public onlyOwner {
        pTokenContractAddress = _pTokenContractAddress;
    }

    function registerUpAddress(address upAddress) public {
        require(
            upAddress != address(0x0),
            "trustAddress can not be address zero"
        );
        require(msg.sender != address(0x0), "sender can not be address zero");
        require(
            DownLinkUpMap[msg.sender].isRegister == false,
            "sender is already register"
        );
        RegisterStruct memory newStruct =
            RegisterStruct({isRegister: true, upAddress: upAddress});
        DownLinkUpMap[msg.sender] = newStruct;
    }

    function registerUpToMain() public {
        require(msg.sender != address(0x0), "sender can not be address zero");
        require(
            DownLinkUpMap[msg.sender].isRegister == false,
            "sender is already register"
        );
        RegisterStruct memory newStruct =
            RegisterStruct({isRegister: true, upAddress: address(0x0)});
        DownLinkUpMap[msg.sender] = newStruct;
    }

    function updateUpAddress(address upAddress) public {
        require(
            upAddress != address(0x0),
            "trustAddress can not be address zero"
        );
        require(msg.sender != address(0x0), "sender can not be address zero");
        require(
            DownLinkUpMap[msg.sender].isRegister == true,
            "sender has not register yet"
        );
        RegisterStruct memory newStruct =
            RegisterStruct({isRegister: true, upAddress: upAddress});
        DownLinkUpMap[msg.sender] = newStruct;
    }

    function updateUpToMain() public {
        require(msg.sender != address(0x0), "sender can not be address zero");
        require(
            DownLinkUpMap[msg.sender].isRegister == true,
            "sender has not register yet"
        );
        RegisterStruct memory newStruct =
            RegisterStruct({isRegister: true, upAddress: address(0x0)});
        DownLinkUpMap[msg.sender] = newStruct;
    }

    function modifyDownAward(address downAddress, uint8 award) public {
        require(msg.sender != address(0x0), "sender can not be address zero");
        require(
            DownLinkUpMap[downAddress].upAddress == msg.sender,
            "sender is not downAddress's upAddress"
        );
        // UpAddressDistributionAwardMap[msg.sender]......
    }

    function mintPtokenForCityAddress(address cityAddress) public {
        require(
            pTokenContractAddress != address(0x0),
            "pTokenContractAddress must be init"
        );
        PToken_Server(pTokenContractAddress).mintFromControler(cityAddress);
    }

    // function restartPerformance() override public{
    //   PerformanceValueMap = {};
    // }

    function getPerformanceWithAddress(address CityAddress)
        public
        override
        returns (uint64)
    {
        return PerformanceValueMap[CityAddress];
    }
}
