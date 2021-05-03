pragma solidity ^0.8.0;

import "./FixidityLib.sol";
import "./CITYSocialServer.sol";
import "./iPerformancePool.sol";

contract PPLControl {
    mapping(address => bytes16) PerformanceMap;
    mapping(address => bytes16) TrustValueMap;
    address[] CityAddressList;
    address[] JXContractAddressList;
    mapping(address => uint256) JXProportionMap;
    uint256 public JXTotal;
    address public CitySocialServerAddress;

    constructor() {}

    function initCitySocialServer(address _CitySocialServerAddress) public {
        CitySocialServerAddress = _CitySocialServerAddress;
    }

    function addJXContractAddress(address contractAddress, uint256 JXProportion)
        public
    {
        require(
            isContract(contractAddress) == true,
            "contractAddress must be contract address"
        );
        require(JXProportion != 0, "JXProportion can not be 0");
        if (JXProportionMap[contractAddress] == 0) {
            JXContractAddressList.push(contractAddress);
        } else {
            JXTotal -= JXProportionMap[contractAddress];
        }
        JXProportionMap[contractAddress] = JXProportion;
        JXTotal += JXProportion;
    }

    function removeJXContractAddress(address contractAddress) public {
        require(
            isContract(contractAddress) == true,
            "contractAddress must be contract address"
        );
        if (JXProportionMap[contractAddress] != 0) {
            JXTotal -= JXProportionMap[contractAddress];
            JXProportionMap[contractAddress] = 0;
            bool isHave;
            uint256 haveIndex;
            for (uint256 i = 0; i < JXContractAddressList.length; i++) {
                if (JXContractAddressList[i] == contractAddress) {
                    isHave = true;
                    haveIndex = i;
                    break;
                }
            }
            if (isHave) {
                JXContractAddressList[haveIndex] = JXContractAddressList[
                    JXContractAddressList.length - 1
                ];
                JXContractAddressList.pop();
            }
        }
    }

    function AutoCalPerfor() public {
        require(
            CitySocialServerAddress != address(0x0),
            "CitySocialServerAddress must be init"
        );
        CityAddressList = CITYSocialServer(CitySocialServerAddress)
            .getCityAddressList();
        for (uint256 i = 0; i < CityAddressList.length; i++) {
            bytes16 zongjixiao = FixidityLib.fromUInt(0);
            for (uint256 j = 0; j < JXContractAddressList.length; j++) {
                zongjixiao = FixidityLib.add(
                    zongjixiao,
                    FixidityLib.mul(
                        FixidityLib.fromUInt(
                            iPerformancePool(JXContractAddressList[j])
                                .getPerformanceWithAddress(CityAddressList[i])
                        ),
                        FixidityLib.div(
                            FixidityLib.fromUInt(
                                JXProportionMap[JXContractAddressList[j]]
                            ),
                            FixidityLib.fromUInt(JXTotal)
                        )
                    )
                );
            }
            PerformanceMap[CityAddressList[i]] = zongjixiao;
        }
        // autoJXRank();
    }

    function autoJXRank() public {
        for (uint256 i = 0; i < CityAddressList.length; i++) {
            address[] memory rankList =
                CITYSocialServer(CitySocialServerAddress)
                    .getUpToDownAddressList(CityAddressList[i]);
            if (rankList.length != 0) {
                for (uint256 j = 0; j < rankList.length; j++) {
                    sort_item(rankList, j);
                }
                bytes16 origin = FixidityLib.fromUInt(50);
                for (uint256 z = 0; z < rankList.length; z++) {
                    address originAddress = rankList[z];
                    TrustValueMap[originAddress] = origin;
                    bytes16 diver = FixidityLib.fromUInt(2);
                    origin = FixidityLib.div(origin, diver);
                }
            }
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function sort_item(address[] memory rankAddress, uint256 index)
        internal
        pure
        returns (bool)
    {
        uint256 min = index;
        for (uint256 i = index; i < rankAddress.length; i++) {
            if (rankAddress[i] < rankAddress[min]) {
                min = i;
            }
        }
        if (min == index) return false;
        address tmp = rankAddress[index];
        rankAddress[index] = rankAddress[min];
        rankAddress[min] = tmp;
        return true;
    }

    function resetCalPerfor() public {
        for (uint256 j = 0; j < JXContractAddressList.length; j++) {
            iPerformancePool(JXContractAddressList[j]).restartPerformance();
        }
        for (uint256 i = 0; i < CityAddressList.length; i++) {
            PerformanceMap[CityAddressList[i]] = FixidityLib.fromUInt(0);
            TrustValueMap[CityAddressList[i]] = FixidityLib.fromUInt(0);
        }
    }

    function getJX(address CityAddress) public view returns (uint256) {
        // require(CityAddress != address(0x0), "CityAddress can not be zero");
        return FixidityLib.toUInt(PerformanceMap[CityAddress]);
    }

    function getJXbytes16(address CityAddress) public view returns (bytes16) {
        // require(CityAddress != address(0x0), "CityAddress can not be zero");
        return PerformanceMap[CityAddress];
    }

    function getTrustValue(address CityAddress) public view returns (uint256) {
        // require(CityAddress != address(0x0), "CityAddress can not be zero");
        return FixidityLib.toUInt(TrustValueMap[CityAddress]);
    }

    function getTrustbyte16Value(address CityAddress)
        public
        view
        returns (bytes16)
    {
        // require(CityAddress != address(0x0), "CityAddress can not be zero");
        return TrustValueMap[CityAddress];
    }

    function JXProportion(address jxcontractAddress)
        public
        view
        returns (uint256)
    {
        return JXProportionMap[jxcontractAddress];
    }

    function getCityAddressList() public view returns (address[] memory) {
        return CityAddressList;
    }

    function getJXContractAddressList() public view returns (address[] memory) {
        return JXContractAddressList;
    }

    function setJxTotal(uint256 _jxTotal) public {
        JXTotal = _jxTotal;
    }
}
