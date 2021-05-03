pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface iGtoken {
    function mintWithPtokenValue(address user, uint256 value) external;

    function checkIsMember(uint64 cityID) external returns (bool);
}

contract GToken_A is ERC20, iGtoken {
    uint64[] public CityIdList;
    mapping(uint64 => bool) ContainCityIDMap;
    mapping(uint64 => uint256) CityIDListIndex;
    address public owner;
    address public pTokenServer;

    modifier onlyOwner() {
        // require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    modifier onlyPTokenServer() {
        // require(msg.sender == pTokenServer, "NOT_PTOKEN_SERVER");
        _;
    }

    constructor() public ERC20("GtokenA", "GTA") {
        owner = msg.sender;
    }

    function initPTokenServer(address _pTokenServer) public onlyOwner {
        pTokenServer = _pTokenServer;
    }

    function mintWithPtokenValue(address user, uint256 value)
        public
        override
        onlyPTokenServer
    {
        _mint(user, value);
    }

    function addCityID(uint64 CityID) public onlyOwner {
        require(
            ContainCityIDMap[CityID] == false,
            "gtoken include ptokenid already"
        );
        CityIdList.push(CityID);
        ContainCityIDMap[CityID] = true;
        CityIDListIndex[CityID] = CityIdList.length - 1;
    }

    function removeCityID(uint64 CityID) public onlyOwner {
        require(
            ContainCityIDMap[CityID] == true,
            "gtoken did not inclue ptokenid yet"
        );
        uint256 deleteIndex = CityIDListIndex[CityID];
        uint256 lastIndex = CityIdList.length - 1;
        CityIdList[deleteIndex] = CityIdList[lastIndex];
        CityIDListIndex[CityIdList[lastIndex]] = deleteIndex;
        CityIdList.pop();
        ContainCityIDMap[CityID] = false;
    }

    function checkIsMember(uint64 CityID) public view override returns (bool) {
        if (ContainCityIDMap[CityID] == true) {
            return true;
        } else {
            return false;
        }
    }
}
