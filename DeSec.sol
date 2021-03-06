pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address owner) internal {
        address msgSender = owner;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }
    
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}

interface IContractEngineer {
}

// ???????????????
contract ContractEngineer is Ownable {

    struct EngineerInfo {
        address owner;
        string nick;
        string headIconUrl;
        string githubUrl;
        string desc;
        address upAccount;
    }

    EngineerInfo[] public engineerInfoList;
    mapping(address => uint256) public engineerInfoMap;

    function register(string memory _nick, string _headIconUrl, string _githubUrl, string _desc, address _upAccount) public {
        EngineerInfo memory engineerInfo = EngineerInfo({owner: msg.sender, nick: _nick, headIconUrl:_headIconUrl, githubUrl: _githubUrl, desc: _desc, upAccount: _upAccount});
        engineerInfoList.push(engineerInfo);
        engineerInfoMap[msg.sender] = engineerInfoList.length;
    }

    function getEngineerNumber() view public returns(uint256) {
        return engineerInfoList.length;
    }

    function applyFor(uint256 projectId) public {

    }
}

// ????????????
contract ProjectManager is Ownable {
    struct PMInfo {
        address owner;
        string nick;
        string headIconUrl;
        string desc;
        address upAccount;
    }

    PMInfo[] public pmInfoList;
    mapping(address => uint256) public pmInfoMap;
    mapping(address => uint256[]) public pmProjectsMap;  // ?????????PM????????????????????????

    function register(string memory _nick, string _headIconUrl, string _desc, address _upAccount) public {
        PMInfo memory pmInfo = PMInfo({owner: msg.sender, nick: _nick, headIconUrl:_headIconUrl, desc: _desc, upAccount: _upAccount});
        pmInfoList.push(pmInfo);
        pmInfoMap[msg.sender] = pmInfoList.length;
    }

    function getPMNumber() view public returns(uint256) {
        return pmInfoList.length;
    }

    function isPM(address account) view public returns(bool) {
        return pmInfoMap[account] != 0;
    }
}

interface IProjectManager {
    function isPM(address account) view external returns(bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IProject {
    function applyFor(address engineer, uint256 index) view external;
}


// ?????????????????????????????????????????????
contract Project is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum Stage { StartUp, Matching, Auditing, Reward }
    enum BugLevel { Low, Middle, High }

    struct ContractInfo {
        string pureCodeUrl;        // ?????????????????????ipfs-URL
        string pureCodeHash;       // ?????????IPFS????????????????????????hash
        string commentedCodeUrl;   // ??????????????????ipfs-URL????????????????????????publicKey????????????????????????????????????????????????????????????????????????????????????
        string commentedCodeHash;  // ?????????IPFS?????????????????????hash
    }

    struct BugInfo {
        BugLevel bugLevelOfEngineer;
        BugLevel bugLevelOfPM;
        string desc;
        uint256 reward;
    }
    
    struct AuditInfo {
        address engineerAddr;
        string commentedCodeUrl;   // ??????????????????????????????????????????????????????ipfs-URL??????????????????????????????????????????
        string commentedCodeHash;  // ??????????????????hash
        uint256 commentReward;     // ?????????????????????
        string testCodeUrl;        // ????????????????????????????????????????????????ipfs-URL??????????????????????????????????????????
        string testCodeHash;       // ????????????hash
        uint256 testReward;        // ?????????????????????
        BugInfo[] bugInfos;        // ??????????????????bug??????

    }

    struct RewardInfo {
        uint256 commentMaxReward;              // ??????????????????
        uint256 testMaxReward;                 // ??????????????????
        uint256 lowLevelBugReward;             // ??????bug??????
        uint256 middleLevelBugReward;          // ??????bug??????
        uint256 highLevelBugReward;            // ??????bug??????
    }

    struct ProjectInfo {
        uint256 id;
        address owner;
        string name;
        string desc;
        string picUrl; 
        bytes32 pubKey;             // ???????????????
        uint256 startTime;          // ??????????????????
        uint256 matchEndTime;       // ????????????????????????????????????
        uint256 auditEndTime;       // ????????????????????????
        Stage stage;                // ????????????????????????
        RewardInfo rewardInfo;      // ??????????????????
        ContractInfo contractInfo;  // ??????????????????????????????
        AuditInfo[] auditInfos;     // ????????????????????????????????????????????????????????????
        uint256 usdtEarnestMoney;   // USDT?????????
    }


    ProjectInfo[] public projectList;       // ?????????????????????
    IProjectManager public projectMgr;  
    IContractEngineer public engineerContract;  
    IERC20 public usdtERC20;
    mapping(uint256 => EnumerableSet.AddressSet) private projectAppliedAddrMap;

    function getProjectNumber() view public returns(uint256) {
        return projectList.length;
    }

    function setPMContract(address pmContractAddr) public onlyOwner {
        projectMgr = IProjectManager(pmContractAddr);
    }

    function setEngineerContract(address engineerContractAddr) public onlyOwner {
        engineerContract = IContractEngineer(engineerContractAddr);
    }

    // ????????????????????????
    function createProject(string memory _name, string memory _desc, string memory _picUrl) public returns(uint256) {
        require(projectMgr.isPM(msg.sender), "Only PM can create project.");
        require(bytes(_name).length >= 2, "The length of project name can NOT less then 2 bytes.");
        AuditInfo[] memory auditInfos;
        ProjectInfo memory projectInfo = ProjectInfo({id: projectList.length, owner: msg.sender, name: _name, desc: _desc, picUrl: _picUrl, pubKey: bytes32(0), startTime: now, 
                                          matchEndTime: 0, auditEndTime: 0,
                                          stage: Stage.StartUp, rewardInfo: RewardInfo(0, 0, 0, 0, 0), contractInfo: ContractInfo("", "", "", ""), 
                                          auditInfos: auditInfos, usdtEarnestMoney: 0});
        projectList.push(projectInfo);
        return projectList.length;
    }

    // ????????????????????????
    function publishProject(uint256 projectId, bytes32 _pubKey, uint256 _matchEndTime, uint256 _auditEndTime,
                           uint256 _commentMaxReward, uint256 _testMaxReward, uint256 _lowDebugReward, uint256 _middleDebugReward, uint256 _highDebugReward,
                           string memory _pureCodeUrl, string memory _pureCodeHash, string memory _commentedCodeUrl, string memory _commentedCodeHash,
                           uint256 _usdtEarnestMoney) public returns(bool){
        require(projectId < projectList.length && projectList[projectId].owner == msg.sender, "Only project's owner can publish the project.");
        require(_matchEndTime == 0 || _matchEndTime > now + 1 days, "Match time should be zero or 1 day later.");
        require(_auditEndTime == 0 || _auditEndTime > now + 2 days, "Match time should be zero or 2 days later.");
        require(_usdtEarnestMoney > 0, "Earnest money should be more than zero.");
        ProjectInfo storage projectInfo = projectList[projectId];
        projectInfo.stage = Stage.Matching;
        projectInfo.pubKey = _pubKey;
        projectInfo.matchEndTime = _matchEndTime;
        projectInfo.auditEndTime = _auditEndTime;

        projectInfo.rewardInfo.commentMaxReward = _commentMaxReward;
        projectInfo.rewardInfo.testMaxReward = _testMaxReward;
        projectInfo.rewardInfo.lowLevelBugReward = _lowDebugReward;
        projectInfo.rewardInfo.middleLevelBugReward = _middleDebugReward;
        projectInfo.rewardInfo.highLevelBugReward = _highDebugReward;

        projectInfo.contractInfo.pureCodeUrl = _pureCodeUrl;
        projectInfo.contractInfo.pureCodeHash = _pureCodeHash;
        projectInfo.contractInfo.commentedCodeUrl = _commentedCodeUrl;
        projectInfo.contractInfo.commentedCodeHash = _commentedCodeHash;

        usdtERC20.transferFrom(msg.sender, address(this), _usdtEarnestMoney);
        projectInfo.usdtEarnestMoney = _usdtEarnestMoney;
        return true;
    }

    // ???????????????????????????????????????????????????????????????
    function applyFor(address engineer, uint256 projectIndex) view public {
        require(msg.sender == address(engineerContract), "Just engineer contract can invoke the interface.");
        require(projectIndex < projectList.length, "Project index is bigger than the length of project list.");
        ProjectInfo memory projectInfo = projectList[projectIndex];
        require(projectInfo.stage == Stage.Matching && projectInfo._matchEndTime > now, "Engineer can't apply for the project now.");
        require(!projectAppliedAddrMap[projectIndex].contains(engineer), "Engineer has been applied for the project.");
        projectAppliedAddrMap[projectIndex].add(engineer);
    }

    function getAppliedEngineerNumber(uint projectIndex) view public returns(uint256) {
        require(projectIndex < projectList.length, "Project index is bigger than the length of project list.");
        return projectAppliedAddrMap[projectIndex].length();
    }

    function getAppliedEngineer(uint256 projectIndex, uint256 engineerIndex) view public returns(address) {
        require(projectIndex < projectList.length, "Project index is bigger than the length of project list.");
        require(engineerIndex < projectAppliedAddrMap[projectIndex].length(), "Engineer index is bigger than the length of engineer list.");
        return projectAppliedAddrMap[projectIndex].at(engineerIndex);
    }
}
