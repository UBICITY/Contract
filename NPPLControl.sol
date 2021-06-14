pragma solidity ^0.8.0;

import "./NCITYSocialServer.sol";
import "./iPerformancePool.sol";
import "./NPToken_Server.sol";

contract NPPLControl {
    address rootAddress = address(0x9999999999999999999999999999999999999999);

    address _OWNER_;
    mapping(address => uint256) ScoreMap;
    mapping(uint256 => mapping(address => uint256)) RollJxMap;
    mapping(uint256 => mapping(address => bool)) RollScoreStateMap;
    mapping(uint256 => mapping(address => uint256)) RollScoreMap;

    address[] _CityAddressList;

    address[] JXContractAddressList;
    mapping(address => uint256) JXProportionMap;
    uint256 public JXTotal;

    uint256 public _sepatorNum;
    uint256 public _rollIndex;

    uint256 constant WAD = 10**18;

    address public CitySocialServerAddress;
    address public PTokenServerAddress;

    constructor() {
        _OWNER_ = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT OWNER");
        _;
    }

    function initCitySocialServer(address _CitySocialServerAddress)
        public
        onlyOwner
    {
        CitySocialServerAddress = _CitySocialServerAddress;
    }

    function initPTokenServer(address _PTokenServerAddress) public onlyOwner {
        PTokenServerAddress = _PTokenServerAddress;
    }

    function oneRollRestart() public {
        require(
            CitySocialServerAddress != address(0x0),
            "CitySocialServerAddress must be init"
        );
        _rollIndex++;
        _CityAddressList = NCITYSocialServer(CitySocialServerAddress)
            .getCityAddressList();
        uint256 sepNum = generateSepNum(_CityAddressList);
        setSepatorNum(sepNum);
    }

    function setSepatorNum(uint256 sepNum) internal {
        _sepatorNum = sepNum;
    }

    function generateSepNum(address[] memory addressList)
        internal
        pure
        returns (uint256)
    {
        uint256 sepNum;
        if (addressList.length % 2 == 0) {
            sepNum = addressList.length / 2;
        } else {
            sepNum = (addressList.length - 1) / 2;
        }
        return sepNum;
    }

    function increaseAddressJx(
        address userAddress,
        address contractAddress,
        uint256 jxValue
    ) public {
        require(
            PTokenServerAddress != address(0x0),
            "PTokenServerAddress must be init"
        );
        require(
            isContract(contractAddress) == true,
            "contractAddress must be contract address"
        );
        require(
            userAddress != address(0),
            "userAddress must not be address zero"
        );
        require(
            JXProportionMap[contractAddress] != 0,
            "contractAddress must be inclue in JXProportionMap"
        );
        require(
            CitySocialServerAddress != address(0x0),
            "CitySocialServerAddress must be init"
        );
        if (userAddress == rootAddress) {
            return;
        }
        address user1 = userAddress;
        for (uint256 index = 0; index < 6; index++) {
            RollJxMap[_rollIndex][userAddress] +=
                (WAD * jxValue * JXProportionMap[contractAddress]) /
                2**index /
                JXTotal;
            uint256 user1ID =
                NPToken_Server(PTokenServerAddress).getCityIDWithAddress(
                    user1
                ) - 1;

            uint256 user2ID;
            if (user1ID >= _sepatorNum) {
                user2ID = user1ID - _sepatorNum;
            } else {
                user2ID = user1ID + _sepatorNum;
            }

            address user2 =
                NPToken_Server(PTokenServerAddress).getAddressWithCityID(
                    user2ID + 1
                );
            bool state = addressPK(user1, user2);
            bool user1_score_state = RollScoreStateMap[_rollIndex][user1];
            bool user2_score_state = RollScoreStateMap[_rollIndex][user2];
            if (!user1_score_state && !user2_score_state) {
                if (state) {
                    ScoreMap[user1] += oneBlockScore();
                    RollScoreMap[_rollIndex][user1] += oneBlockScore();
                    RollScoreStateMap[_rollIndex][user1] = true;
                } else {
                    ScoreMap[user2] += oneBlockScore();
                    RollScoreMap[_rollIndex][user2] += oneBlockScore();
                    RollScoreStateMap[_rollIndex][user2] = true;
                }
            } else if (user1_score_state && !user2_score_state) {
                if (!state) {
                    ScoreMap[user1] -= oneBlockScore();
                    RollScoreMap[_rollIndex][user1] -= oneBlockScore();
                    RollScoreStateMap[_rollIndex][user1] = false;
                    ScoreMap[user2] += oneBlockScore();
                    RollScoreMap[_rollIndex][user2] += oneBlockScore();
                    RollScoreStateMap[_rollIndex][user2] = true;
                }
            } else if (!user1_score_state && user2_score_state) {
                if (state) {
                    ScoreMap[user2] -= oneBlockScore();
                    RollScoreMap[_rollIndex][user2] -= oneBlockScore();
                    RollScoreStateMap[_rollIndex][user2] = false;
                    ScoreMap[user1] += oneBlockScore();
                    RollScoreMap[_rollIndex][user1] += oneBlockScore();
                    RollScoreStateMap[_rollIndex][user1] = true;
                }
            }

            address upAddress =
                NCITYSocialServer(CitySocialServerAddress).getUpAddress(user1);
            if (upAddress == rootAddress) {
                break;
            } else {
                user1 = upAddress;
            }
        }
    }

    function oneBlockScore() internal view returns (uint256) {
        return JXTotal / _sepatorNum;
    }

    function addressPK(address user1, address user2)
        internal
        view
        returns (bool)
    {
        require(
            user1 != address(0) && user2 != address(0),
            "pkAddress can not be address(0)"
        );
        require(user1 != user2, "pkAddress can not be equal");
        uint256 user1JX = RollJxMap[_rollIndex][user1];
        uint256 user2JX = RollJxMap[_rollIndex][user2];
        if (user1JX >= user2JX) {
            return true;
        } else {
            return false;
        }
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

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getCanMintCityNum(address CityAddress)
        public
        view
        returns (uint256)
    {
        require(CityAddress != address(0x0), "CityAddress can not be zero");
        return ScoreMap[CityAddress] - RollScoreMap[_rollIndex][CityAddress];
    }

    function GetJXProportion(address JXContractAddress)
        public
        view
        returns (uint256)
    {
        return JXProportionMap[JXContractAddress];
    }

    function getJXContractAddressList() public view returns (address[] memory) {
        return JXContractAddressList;
    }

    // test
    function setJxTotal(uint256 _jxTotal) public {
        JXTotal = _jxTotal;
    }
}
