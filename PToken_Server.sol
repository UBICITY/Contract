pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./GToken_A.sol";



contract PToken_Server is ERC1155 {
    mapping(address => uint64) public CITYAddressMap;
    mapping(uint64 => address) public CITYIDMap;
    address[] public CityAddress;
    mapping(uint64 => uint256) public startBlock;
    uint64 public nowCityID = 1;
    uint8 public rewardCoefficient = 1;

    function mintGrow() public {
        require(
            CITYAddressMap[msg.sender] != 0,
            "msg.sender must be a cityMember"
        );
        uint64 cityID = CITYAddressMap[msg.sender];
        uint256 startBlockNum = startBlock[cityID];
        uint256 currentBlockNum = block.number;
        uint256 amount = (currentBlockNum - startBlockNum) * rewardCoefficient;
        startBlock[cityID] = currentBlockNum;
        bytes memory data;
        _mint(msg.sender, cityID, amount, data);
    }

    function mintAutoGrow(
        address rewardAddress,
        uint64 rewardCityID // external // onlyOwner
    ) public {
        require(
            CITYAddressMap[rewardAddress] != 0,
            "rewardAddress must be a cityMember"
        );
        uint64 CityID = CITYAddressMap[rewardAddress];
        require(
            rewardCityID == CityID,
            "rewardAddress and rewardCityID must be a pair"
        );
        uint256 startBlockNum = startBlock[rewardCityID];
        uint256 currentBlockNum = block.number;
        uint256 amount = (currentBlockNum - startBlockNum) * rewardCoefficient;
        startBlock[rewardCityID] = currentBlockNum;
        bytes memory data;
        _mint(rewardAddress, rewardCityID, amount, data);
    }

    function mintAutoGrowAllUser(
        uint64 startIndex,
        uint64 limit // external // onlyOwner
    ) public {
        require(CityAddress.length > startIndex, "must be enough city member");
        uint64 circleLimit = 0;
        if (CityAddress.length - startIndex > limit) {
            circleLimit = limit;
        } else {
            circleLimit = uint64(CityAddress.length) - startIndex;
        }
        for (uint64 i = startIndex; i < circleLimit + startIndex; i++) {
            mintAutoGrow(CityAddress[i], CITYAddressMap[CityAddress[i]]);
        }
    }

    constructor() public ERC1155("") {}

    function mintFromControler(address deployAccount) public {
        require(
            CITYAddressMap[deployAccount] == 0,
            "the address can only make one token"
        );
        CITYAddressMap[deployAccount] = nowCityID;
        CITYIDMap[nowCityID] = deployAccount;
        CityAddress.push(deployAccount);
        startBlock[nowCityID] = block.number;
        bytes memory data;
        _mint(deployAccount, nowCityID, 10000, data);
        nowCityID++;
    }

    function burnMoney(
        address account,
        uint64 id,
        uint256 amount
    ) public {
        require(msg.sender == account, "only account user can call this");
        _burn(account, id, amount);
    }

    function mintWithGtokenContract(
        uint64 CityID,
        address GtokenContract,
        uint256 value
    ) public {
        require(
            CITYIDMap[CityID] != address(0x0),
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
}
