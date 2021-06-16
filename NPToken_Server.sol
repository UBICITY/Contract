pragma solidity ^0.8.0;

import "./NERC1155.sol";
import "./GToken_A.sol";

contract NPToken_Server is NERC1155 {
    mapping(address => uint256) public CITYAddressMap;
    address[] public CityAddress;
    uint256 public nowCityID = 1;

    address _OWNER_;

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT OWNER");
        _;
    }

    constructor() public NERC1155("") {
        _OWNER_ = msg.sender;
    }

    function mintGrow() public {
        require(
            CITYAddressMap[msg.sender] != 0,
            "msg.sender must be a CityMember"
        );
        uint256 cityID = CITYAddressMap[msg.sender];
        uint256 startBlockNum = AddressRewardMap[cityID];
        uint256 currentBlockNum = block.number;
        uint256 amount = (currentBlockNum - startBlockNum) * rewardCoefficient;
        AddressRewardMap[cityID] = currentBlockNum;
        bytes memory data;
        _mint(msg.sender, cityID, amount, data);
    }

    function mintAutoGrow(
        address rewardAddress,
        uint256 rewardCityID // external
    ) public onlyOwner {
        require(
            CITYAddressMap[rewardAddress] != 0,
            "rewardAddress must be a cityMember"
        );
        uint256 CityID = CITYAddressMap[rewardAddress];
        require(
            rewardCityID == CityID,
            "rewardAddress and rewardCityID must be a pair"
        );
        uint256 startBlockNum = AddressRewardMap[rewardCityID];
        uint256 currentBlockNum = block.number;
        uint256 amount = (currentBlockNum - startBlockNum) * rewardCoefficient;
        AddressRewardMap[rewardCityID] = currentBlockNum;
        bytes memory data;
        _mint(rewardAddress, rewardCityID, amount, data);
    }

    function mintAutoGrowAllUser(
        uint256 startIndex,
        uint256 limit // external
    ) public onlyOwner {
        require(CityAddress.length > startIndex, "must be enough city member");
        uint256 circleLimit = 0;
        if (CityAddress.length - startIndex > limit) {
            circleLimit = limit;
        } else {
            circleLimit = uint256(CityAddress.length) - startIndex;
        }
        for (uint256 i = startIndex; i < circleLimit + startIndex; i++) {
            mintAutoGrow(CityAddress[i], CITYAddressMap[CityAddress[i]]);
        }
    }

    function mintFromControler(address deployAccount) public {
        require(
            CITYAddressMap[deployAccount] == 0,
            "the address can only make one token"
        );
        CITYAddressMap[deployAccount] = nowCityID;
        IDMap[nowCityID] = deployAccount;
        CityAddress.push(deployAccount);
        AddressRewardMap[nowCityID] = block.number;
        bytes memory data;
        _mint(deployAccount, nowCityID, 10000, data);
        nowCityID++;
    }

    function burnMoney(
        address account,
        uint256 id,
        uint256 amount
    ) public {
        require(msg.sender == account, "only account user can call this");
        _burn(account, id, amount);
    }

    function mintWithGtokenContract(
        uint256 CityID,
        address GtokenContract,
        uint256 value
    ) public {
        require(
            IDMap[CityID] != address(0),
            "CityID must be include in ptoken"
        );
        require(
            GToken_A(GtokenContract).checkIsMember(CityID) == true,
            "CityID must be include in gtoken"
        );
        require(
            balanceOf(msg.sender, CityID) >= value,
            "user balance must be greater than value"
        );
        GToken_A(GtokenContract).mintWithPtokenValue(msg.sender, value);
        burnMoney(msg.sender, CityID, value);
    }

    function getCityIDWithAddress(address userAddress)
        public
        view
        returns (uint256)
    {
        require(
            CITYAddressMap[userAddress] != 0,
            "userAddress must be include in ptoken"
        );
        return CITYAddressMap[userAddress];
    }

    function getAddressWithCityID(uint256 cityID)
        public
        view
        returns (address)
    {
        require(
            IDMap[cityID] != address(0),
            "cityID must be include in ptoken"
        );
        return IDMap[cityID];
    }
}
