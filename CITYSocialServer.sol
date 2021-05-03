pragma solidity ^0.8.0;

import "./PToken_Server.sol";
import "./iPerformancePool.sol";
import "./FixidityLib.sol";


contract CITYSocialServer is iPerformancePool {
    struct RegisterStruct {
        bool isRegister;
        address upAddress;
    }

    mapping(address => RegisterStruct) DownLinkUpMap;

    address rootAddress = address(0x9999999999999999999999999999999999999999);
    address[] CityAddressList = [rootAddress];
    mapping(address => bool) isCityAddressMap;
    mapping(address => uint256) public SocialJXMap;

    mapping(address => address[]) UpToDownAddressMap;

    address public owner;
    address public pTokenContractAddress;

    modifier onlyOwner() {
        // require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getCityAddressList() public view returns (address[] memory) {
        return CityAddressList;
    }

    function getUpToDownAddressList(address upAddress)
        public
        view
        returns (address[] memory)
    {
        return UpToDownAddressMap[upAddress];
    }

    function initPTokenServer(address _pTokenContractAddress) public onlyOwner {
        pTokenContractAddress = _pTokenContractAddress;
    }

    function registerUpAddress(address downAddress, address upAddress) public {
        require(
            upAddress != address(0x0),
            "trustAddress can not be address zero"
        );
        require(
            isCityAddressMap[upAddress] == true,
            "upAddress must be CityAddress"
        );
        RegisterAddressAssociation(downAddress, upAddress);
    }

    function registerUpToMain(address downAddress) public {
        // require(msg.sender == downAddress, "msg.sender must be equal to downAddress");
        RegisterAddressAssociation(downAddress, rootAddress);
    }

    function RegisterAddressAssociation(address downAddress, address upAddress)
        internal
    {
        require(
            isCityAddressMap[downAddress] == false,
            "msg.sender must not be CityAddress"
        );
        require(
            DownLinkUpMap[downAddress].isRegister == false,
            "when register, msg.sender must not be CityAddress"
        );
        RegisterStruct memory newStruct =
            RegisterStruct({isRegister: true, upAddress: upAddress});
        DownLinkUpMap[downAddress] = newStruct;
        CityAddressList.push(downAddress);
        isCityAddressMap[downAddress] = true;
        UpToDownAddressMap[upAddress].push(downAddress);
        mintPtokenForCityAddress(downAddress);
        JxProcess(upAddress);
    }

    function JxProcess(address upAddress) internal {
        bool isContinue = true;
        address _supAddress = upAddress;
        do {
            if (_supAddress == rootAddress) {
                isContinue = false;
                SocialJXMap[_supAddress] += 1;
            } else {
                SocialJXMap[_supAddress] += 1;
                if (DownLinkUpMap[_supAddress].isRegister == false) {
                    isContinue = false;
                } else {
                    _supAddress = DownLinkUpMap[_supAddress].upAddress;
                }
            }
        } while (isContinue);
    }

    function mintPtokenForCityAddress(address cityAddress) internal {
        require(
            pTokenContractAddress != address(0x0),
            "pTokenContractAddress must be init"
        );
        PToken_Server(pTokenContractAddress).mintFromControler(cityAddress);
    }

    function getPerformanceWithAddress(address CityAddress)
        public
        view
        override
        returns (uint256)
    {
        return SocialJXMap[CityAddress];
    }

    function restartPerformance() public override {
        for (uint256 i = 0; i < CityAddressList.length; i++) {
            SocialJXMap[CityAddressList[i]] = 0;
        }
    }
}
