pragma solidity ^0.8.0;

import "./NPToken_Server.sol";
import "./iPerformancePool.sol";
import "./NPPLControl.sol";

contract NCITYSocialServer is iPerformancePool {
    struct RegisterStruct {
        bool isRegister;
        address upAddress;
    }

    mapping(address => RegisterStruct) DownLinkUpMap;

    address rootAddress = address(0x9999999999999999999999999999999999999999);
    address[] CityAddressList;
    mapping(address => bool) isCityAddressMap;
    mapping(address => uint256) SocialJXMap;

    mapping(address => address[]) UpToDownAddressMap;

    address owner;
    address public pTokenContractAddress;
    address public pPLControlContractAddress;
    address public selfAddress;

    modifier onlyOwner() {
      require(msg.sender == owner, "NOT_OWNER");
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

    function initPPLControlServer(address _pPLControlContractAddress)
        public
        onlyOwner
    {
        pPLControlContractAddress = _pPLControlContractAddress;
    }

    function initSelfServer(address _selfContractAddress) public onlyOwner {
        selfAddress = _selfContractAddress;
    }

    // 用户传入自己的授信地址进行register
    function registerUpAddress(address downAddress, address upAddress) public {
        // 入参地址格式检查
        require(
            upAddress != address(0x0),
            "trustAddress can not be address zero"
        );
        // require(msg.sender == downAddress, "msg.sender must be equal to downAddress");
        // 判断upAddress是否为CityAddress
        require(
            isCityAddressMap[upAddress] == true,
            "upAddress must be CityAddress"
        );
        RegisterAddressAssociation(downAddress, upAddress);
    }

    function registerUpToMain(address downAddress) public {
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
        require(
            selfAddress != address(0) &&
                pPLControlContractAddress != address(0),
            "selfAddress || pPLControlContractAddress must be init"
        );
        RegisterStruct memory newStruct =
            RegisterStruct({isRegister: true, upAddress: upAddress});
        DownLinkUpMap[downAddress] = newStruct;
        CityAddressList.push(downAddress);
        isCityAddressMap[downAddress] = true;
        UpToDownAddressMap[upAddress].push(downAddress);
        mintPtokenForCityAddress(downAddress);
        NPPLControl(pPLControlContractAddress).increaseAddressJx(
            upAddress,
            selfAddress,
            1
        );
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
                    // 不应该会走入这个逻辑里边来
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
        NPToken_Server(pTokenContractAddress).mintFromControler(cityAddress);
    }

    function getPerformanceWithAddress(address CityAddress)
        public
        view
        override
        returns (uint256)
    {
        return SocialJXMap[CityAddress];
    }

    function getUpAddress(address userAddress) public view returns (address) {
        require(
            isCityAddressMap[userAddress] == true,
            "userAddress must be cityAddress"
        );
        return DownLinkUpMap[userAddress].upAddress;
    }

    function restartPerformance() public override {
        for (uint256 i = 0; i < CityAddressList.length; i++) {
            SocialJXMap[CityAddressList[i]] = 0;
        }
    }
}
