import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.1;

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(
        Role storage role,
        address account
    ) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract AdminControl is Ownable {
    using Roles for Roles.Role;

    Roles.Role private _controllerRoles;

    modifier onlyMinterController() {
        require(
            hasRole(msg.sender),
            "AdminControl: sender must has minting role"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(msg.sender),
            "AdminControl: sender must has minting role"
        );
        _;
    }

    constructor() {
        _grantRole(msg.sender);
    }

    function grantMinterRole(address account) public onlyOwner {
        _grantRole(account);
    }

    function revokeMinterRole(address account) public onlyOwner {
        _revokeRole(account);
    }

    function hasRole(address account) public view returns (bool) {
        return _controllerRoles.has(account);
    }

    function _grantRole(address account) internal {
        _controllerRoles.add(account);
    }

    function _revokeRole(address account) internal {
        _controllerRoles.remove(account);
    }
}

library StringUtil {
    /**
     * @dev Return the count of the dot "." in a string
     */
    function dotCount(string memory s) internal pure returns (uint) {
        s; // Don't warn about unused variables
        // Starting here means the LSB will be the byte we care about
        uint ptr;
        uint end;
        assembly {
            ptr := add(s, 1)
            end := add(mload(s), ptr)
        }
        uint num = 0;
        uint len = 0;
        for (len; ptr < end; len++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b == 0x2e) {
                num += 1;
            }
            ptr += 1;
        }
        return num;
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function toHash(string memory _s) internal pure returns (bytes32) {
        return keccak256(abi.encode(_s));
    }

    function isEmpty(string memory _s) internal pure returns (bool) {
        return bytes(_s).length == 0;
    }

    function compare(
        string memory _a,
        string memory _b
    ) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(
        string memory _a,
        string memory _b
    ) internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }

    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(
        string memory _haystack,
        string memory _needle
    ) internal pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) return -1;
        else if (h.length > (2 ** 128 - 1))
            // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
            return -1;
        else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) // found the first char of b
                {
                    subindex = 1;
                    while (
                        subindex < n.length &&
                        (i + subindex) < h.length &&
                        h[i + subindex] == n[subindex] // search until the chars don't match or until we reach the end of a or b
                    ) {
                        subindex++;
                    }
                    if (subindex == n.length) return int(i);
                }
            }
            return -1;
        }
    }
}

abstract contract KeyStorage {
    mapping(uint256 => string) private _keys;

    function getKey(uint256 keyHash) public view returns (string memory) {
        return _keys[keyHash];
    }

    function getKeys(
        uint256[] calldata hashes
    ) public view returns (string[] memory values) {
        values = new string[](hashes.length);
        for (uint256 i = 0; i < hashes.length; i++) {
            values[i] = getKey(hashes[i]);
        }
    }

    function addKey(string memory key) external {
        _addKey(uint256(keccak256(abi.encodePacked(key))), key);
    }

    function _existsKey(uint256 keyHash) internal view returns (bool) {
        return bytes(_keys[keyHash]).length > 0;
    }

    function _addKey(uint256 keyHash, string memory key) internal {
        if (!_existsKey(keyHash)) {
            _keys[keyHash] = key;
        }
    }
}

interface IRecordReader {
    /**
     * @dev Function to get record.
     * @param key The key to query the value of.
     * @param tokenId The token id to fetch.
     * @return The value string.
     */
    function get(
        string calldata key,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @dev Function to get multiple record.
     * @param keys The keys to query the value of.
     * @param tokenId The token id to fetch.
     * @return The values.
     */
    function getMany(
        string[] calldata keys,
        uint256 tokenId
    ) external view returns (string[] memory);

    /**
     * @dev Function get value by provied key hash.
     * @param keyHash The key to query the value of.
     * @param tokenId The token id to set.
     */
    function getByHash(
        uint256 keyHash,
        uint256 tokenId
    ) external view returns (string memory key, string memory value);

    /**
     * @dev Function get values by provied key hashes.
     * @param keyHashes The key to query the value of.
     * @param tokenId The token id to set.
     */
    function getManyByHash(
        uint256[] calldata keyHashes,
        uint256 tokenId
    ) external view returns (string[] memory keys, string[] memory values);
}

interface IRecordStorage is IRecordReader {
    event Set(
        uint256 indexed tokenId,
        string indexed keyIndex,
        string indexed valueIndex,
        string key,
        string value
    );

    event NewKey(uint256 indexed tokenId, string indexed keyIndex, string key);

    event ResetRecords(uint256 indexed tokenId);

    /**
     * @dev Set record by key
     * @param key The key set the value of
     * @param value The value to set key to
     * @param tokenId ERC-721 token id to set
     */
    function set(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) external;

    /**
     * @dev Set records by keys
     * @param keys The keys set the values of
     * @param values Records values
     * @param tokenId ERC-721 token id of the domain
     */
    function setMany(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) external;

    /**
     * @dev Set record by key hash
     * @param keyHash The key hash set the value of
     * @param value The value to set key to
     * @param tokenId ERC-721 token id to set
     */
    function setByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) external;

    /**
     * @dev Set records by key hashes
     * @param keyHashes The key hashes set the values of
     * @param values Records values
     * @param tokenId ERC-721 token id of the domain
     */
    function setManyByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) external;

    /**
     * @dev Reset all domain records and set new ones
     * @param keys New record keys
     * @param values New record values
     * @param tokenId ERC-721 token id of the domain
     */
    function reconfigure(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) external;

    /**
     * @dev Function to reset all existing records on a domain.
     * @param tokenId ERC-721 token id to set.
     */
    function reset(uint256 tokenId) external;
}

abstract contract RecordStorage is KeyStorage, IRecordStorage {
    /// @dev mapping of presetIds to keyIds to values
    mapping(uint256 => mapping(uint256 => string)) internal _records;

    /// @dev mapping of tokenIds to presetIds
    mapping(uint256 => uint256) internal _tokenPresets;

    function get(
        string calldata key,
        uint256 tokenId
    ) external view override returns (string memory value) {
        value = _get(key, tokenId);
    }

    function getMany(
        string[] calldata keys,
        uint256 tokenId
    ) external view override returns (string[] memory values) {
        values = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = _get(keys[i], tokenId);
        }
    }

    function getByHash(
        uint256 keyHash,
        uint256 tokenId
    ) external view override returns (string memory key, string memory value) {
        (key, value) = _getByHash(keyHash, tokenId);
    }

    function getManyByHash(
        uint256[] calldata keyHashes,
        uint256 tokenId
    )
        external
        view
        override
        returns (string[] memory keys, string[] memory values)
    {
        keys = new string[](keyHashes.length);
        values = new string[](keyHashes.length);
        for (uint256 i = 0; i < keyHashes.length; i++) {
            (keys[i], values[i]) = _getByHash(keyHashes[i], tokenId);
        }
    }

    function _presetOf(
        uint256 tokenId
    ) internal view virtual returns (uint256) {
        return _tokenPresets[tokenId] == 0 ? tokenId : _tokenPresets[tokenId];
    }

    function _set(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) internal {
        uint256 keyHash = uint256(keccak256(abi.encodePacked(key)));
        _addKey(keyHash, key);
        _set(keyHash, key, value, tokenId);
    }

    function _setMany(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) internal {
        for (uint256 i = 0; i < keys.length; i++) {
            _set(keys[i], values[i], tokenId);
        }
    }

    function _setByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) internal {
        require(_existsKey(keyHash), "RecordStorage: KEY_NOT_FOUND");
        _set(keyHash, getKey(keyHash), value, tokenId);
    }

    function _setManyByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) internal {
        for (uint256 i = 0; i < keyHashes.length; i++) {
            _setByHash(keyHashes[i], values[i], tokenId);
        }
    }

    function _reconfigure(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) internal {
        _reset(tokenId);
        _setMany(keys, values, tokenId);
    }

    function _reset(uint256 tokenId) internal {
        _tokenPresets[tokenId] = uint256(
            keccak256(abi.encodePacked(_presetOf(tokenId)))
        );
        emit ResetRecords(tokenId);
    }

    function _get(
        string memory key,
        uint256 tokenId
    ) private view returns (string memory) {
        return _get(uint256(keccak256(abi.encodePacked(key))), tokenId);
    }

    function _getByHash(
        uint256 keyHash,
        uint256 tokenId
    ) private view returns (string memory key, string memory value) {
        key = getKey(keyHash);
        value = _get(keyHash, tokenId);
    }

    function _get(
        uint256 keyHash,
        uint256 tokenId
    ) private view returns (string memory) {
        return _records[_presetOf(tokenId)][keyHash];
    }

    function _set(
        uint256 keyHash,
        string memory key,
        string memory value,
        uint256 tokenId
    ) private {
        if (bytes(_records[_presetOf(tokenId)][keyHash]).length == 0) {
            emit NewKey(tokenId, key, key);
        }

        _records[_presetOf(tokenId)][keyHash] = value;
        emit Set(tokenId, key, value, key, value);
    }
}

abstract contract WhiteList is AdminControl {
    mapping(address => uint256) public _whiteList;

    bool public _isWhiteListActive = false;

    function setWhiteListActive() public onlyOwner {
        _isWhiteListActive = !_isWhiteListActive;
    }

    function addWhiteLists(
        address[] calldata accounts,
        uint256 numbers
    ) public onlyMinterController {
        for (uint256 i = 0; i < accounts.length; i++) {
            _whiteList[accounts[i]] = numbers;
        }
    }

    function addWhiteList(
        address account,
        uint256 numbers
    ) public onlyMinterController {
        _whiteList[account] = numbers;
    }

    function numberInWhiteList(address addr) public view returns (uint256) {
        return _whiteList[addr];
    }

    function chkInWhiteList(address addr) public view returns (bool) {
        return _whiteList[addr] > 0;
    }
}

abstract contract BookingList is AdminControl {
    mapping(bytes => string) public _bookingList;

    bool public _isBookingListActive = false;

    function setBookingListActive() public onlyOwner {
        _isBookingListActive = !_isBookingListActive;
    }

    function addBookingLists(
        string[] calldata names
    ) public onlyMinterController {
        for (uint256 i = 0; i < names.length; i++) {
            _bookingList[bytes(names[i])] = names[i];
        }
    }

    function addBookingList(string calldata name) public onlyMinterController {
        _bookingList[bytes(name)] = name;
    }

    function removeBookingList(
        string calldata name
    ) public onlyMinterController {
        delete _bookingList[bytes(name)];
    }

    function chkInBookingList(string calldata name) public view returns (bool) {
        string memory _name = _bookingList[bytes(name)];
        return bytes(_name).length > 0;
    }
}

interface ISubscriptionOwner {
    function getSubscriptionOwner() external view returns (address);
}

contract ArtheraDns is
    IERC721Enumerable,
    ERC721,
    BookingList,
    WhiteList,
    RecordStorage,
    ISubscriptionOwner
{
    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.UintSet;

    event NewURI(uint256 indexed tokenId, string tokenUri);

    mapping(uint256 => EnumerableSet.UintSet) private _subTokens;

    mapping(uint256 => string) public _tokenURIs;

    mapping(uint256 => bytes) public _nativeAddress;

    mapping(uint256 => address) internal _tokenResolvers;

    mapping(address => uint256) private _tokenReverses;

    mapping(uint256 => string) private _tlds;

    string private _nftBaseURI = "";

    bool public _saleIsActive = true;

    bool public _saleTwoCharIsActive = false;

    uint256 private _price = 1;

    uint256 private _2chartimes = 100;

    uint256 private _3chartimes = 20;

    uint256 private _4chartimes = 5;

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _;
    }

    constructor() ERC721("DID Identity", "TDID") {}

    function isApprovedOrOwner(
        address account,
        uint256 tokenId
    ) external view returns (bool) {
        return _isApprovedOrOwner(account, tokenId);
    }

    function getOwner(string memory domain) external view returns (address) {
        string memory _domain = StringUtil.toLower(domain);
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_domain)));
        return ownerOf(tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function setTimes(
        uint256 _2chartimenew,
        uint256 _3chartimenew,
        uint256 _4chartimenew
    ) public onlyOwner {
        _2chartimes = _2chartimenew;
        _3chartimes = _3chartimenew;
        _4chartimes = _4chartimenew;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function setSaleStateTwoChar() public onlyOwner {
        _saleTwoCharIsActive = !_saleTwoCharIsActive;
    }

    function setTLD(string memory _tld) public onlyOwner {
        uint256 tokenId = genTokenId(_tld);
        _tlds[tokenId] = _tld;
    }

    function isTLD(string memory _tld) public view returns (bool) {
        bool isExist = false;
        uint256 tokenId = genTokenId(_tld);
        if (bytes(_tlds[tokenId]).length != 0) {
            isExist = true;
        }
        return isExist;
    }

    function setSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return _nftBaseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _nftBaseURI = _uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "TRC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI, tokenId));
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "TRC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function buyDomain(
        string memory domain,
        string memory tld
    ) external payable {
        require(_saleIsActive, "Sale must be active to buy");

        require(bytes(tld).length != 0, "Top level domain must be non-empty");

        require(isTLD(tld) == true, "Top level domain not exist");

        require(StringUtil.dotCount(domain) == 0, "Domains cannot contain dot");

        uint256 _length = bytes(domain).length;

        require(_length != 0, "Domain must be non-empty");

        require(_length >= 2, "Domain requires at least 2 characters");

        // Check BookingList
        if (_isBookingListActive == true) {
            string memory name = _bookingList[bytes(domain)];
            require(bytes(name).length == 0, "This name is already reserved");
        }

        // Check WhiteList
        if (_isWhiteListActive == true) {
            uint256 numbers = _whiteList[msg.sender];
            require(numbers > 0, "The address is not in the Whitelist");
            require(
                numbers >= balanceOf(msg.sender),
                "Exceeded max available to purchase"
            );
        }

        if (_length == 2) {
            require(
                _saleTwoCharIsActive == true,
                "2 Character domain names need to be allowed to buy"
            );

            require(
                msg.value >= _price.mul(_2chartimes),
                "Insufficient Token or Token value sent is not correct"
            );
        }

        if (_length == 3) {
            require(
                msg.value >= _price.mul(_3chartimes),
                "Insufficient Token or Token value sent is not correct"
            );
        }

        if (_length == 4) {
            require(
                msg.value >= _price.mul(_4chartimes),
                "Insufficient Token or Token value sent is not correct"
            );
        }

        if (_length >= 5) {
            require(
                msg.value >= _price,
                "Insufficient Token or Token value sent is not correct"
            );
        }

        string memory _domain = StringUtil.toLower(domain);

        string memory _tld = StringUtil.toLower(tld);

        _domain = string(abi.encodePacked(_domain, ".", _tld));

        uint256 tokenId = genTokenId(_domain);

        require(!_exists(tokenId), "Domain already exists");

        _safeMint(msg.sender, tokenId);

        _setTokenURI(tokenId, _domain);

        emit NewURI(tokenId, _domain);
    }

    function registerDomain(
        address to,
        string memory domain,
        string memory tld
    ) external {
        require(to != address(0), "To address is null");

        require(bytes(tld).length != 0, "Top level domain must be non-empty");

        require(isTLD(tld) == true, "Top level domain not exist");

        require(bytes(domain).length != 0, "Domain must be non-empty");

        require(StringUtil.dotCount(domain) == 0, "Domain not support");

        string memory _domain = StringUtil.toLower(domain);

        string memory _tld = StringUtil.toLower(tld);

        _domain = string(abi.encodePacked(_domain, ".", _tld));

        uint256 tokenId = genTokenId(_domain);

        require(!_exists(tokenId), "Domain already exists");

        _safeMint(to, tokenId);

        _setTokenURI(tokenId, _domain);

        emit NewURI(tokenId, _domain);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "TRC721: transfer caller is not owner nor approved"
        );

        _reset(tokenId);

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "TRC721: transfer caller is not owner nor approved"
        );

        _reset(tokenId);

        _safeTransfer(from, to, tokenId, _data);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "TRC721Burnable: caller is not owner nor approved"
        );

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        if (_tokenReverses[_msgSender()] != 0) {
            delete _tokenReverses[_msgSender()];
        }

        if (_tokenResolvers[tokenId] != address(0)) {
            delete _tokenResolvers[tokenId];
        }

        _reset(tokenId);

        _burn(tokenId);
    }

    function setOwner(
        address to,
        uint256 tokenId
    ) external onlyApprovedOrOwner(tokenId) {
        _transfer(ownerOf(tokenId), to, tokenId);
    }

    /**
     * Begin: set and get Reverses
     */
    function reverseOf(address account) public view returns (string memory) {
        uint256 tokenId = _tokenReverses[account];
        require(tokenId != 0, "ReverseResolver: REVERSE_RECORD_IS_EMPTY");
        require(
            _isApprovedOrOwner(account, tokenId),
            "ReverseResolver: ACCOUNT_IS_NOT_APPROVED_OR_OWNER"
        );
        return _tokenURIs[tokenId];
    }

    function setReverse(uint256 tokenId) public {
        address _sender = _msgSender();
        require(
            _isApprovedOrOwner(_sender, tokenId),
            "ReverseResolver: SENDER_IS_NOT_APPROVED_OR_OWNER"
        );
        _tokenReverses[_sender] = tokenId;
    }

    function removeReverse() public {
        address _sender = _msgSender();
        uint256 tokenId = _tokenReverses[_sender];
        require(tokenId != 0, "ReverseResolver: REVERSE_RECORD_IS_EMPTY");
        delete _tokenReverses[_sender];
    }

    /**
     * End: set and get Reverses
     */

    /**
     * Begin set and get Resolver
     **/

    function setResolver(
        uint256 tokenId,
        address resolver
    ) external onlyApprovedOrOwner(tokenId) {
        _setResolver(tokenId, resolver);
    }

    function resolverOf(uint256 tokenId) external view returns (address) {
        if (_exists(tokenId) == false) {
            return address(0);
        }
        address resolver = _tokenResolvers[tokenId];
        if (resolver == address(0)) {
            resolver = address(this);
        }
        return resolver;
    }

    function removeResolver(
        uint256 tokenId
    ) external onlyApprovedOrOwner(tokenId) {
        require(tokenId != 0, "ReverseResolver: REVERSE_RECORD_IS_EMPTY");
        delete _tokenResolvers[tokenId];
    }

    function _setResolver(uint256 tokenId, address resolver) internal {
        require(_exists(tokenId));
        _tokenResolvers[tokenId] = resolver;
    }

    /**
     * End:Resolver
     */

    /**
     * Begin: Subdomain
     */
    function registerSubDomain(
        address to,
        uint256 tokenId,
        string memory sub
    ) external onlyApprovedOrOwner(tokenId) {
        _safeMintSubDomain(to, tokenId, sub, "");
    }

    function burnSubDomain(
        uint256 tokenId,
        string memory sub
    ) external onlyApprovedOrOwner(tokenId) {
        _burnSubDomain(tokenId, sub);
    }

    function _safeMintSubDomain(
        address to,
        uint256 tokenId,
        string memory sub,
        bytes memory _data
    ) internal {
        require(to != address(0));
        require(bytes(sub).length != 0);
        require(StringUtil.dotCount(sub) == 0);
        require(_exists(tokenId));

        string memory _sub = StringUtil.toLower(sub);

        bytes memory _newUri = abi.encodePacked(_sub, ".", _tokenURIs[tokenId]);

        uint256 _newTokenId = genTokenId(string(_newUri));

        uint256 count = StringUtil.dotCount(_tokenURIs[tokenId]);

        if (count == 1) {
            _subTokens[tokenId].add(_newTokenId);
        }

        if (bytes(_data).length != 0) {
            _safeMint(to, _newTokenId, _data);
        } else {
            _safeMint(to, _newTokenId);
        }

        _setTokenURI(_newTokenId, string(_newUri));

        emit NewURI(_newTokenId, string(_newUri));
    }

    function _burnSubDomain(uint256 tokenId, string memory sub) internal {
        string memory _sub = StringUtil.toLower(sub);

        bytes memory _newUri = abi.encodePacked(_sub, ".", _tokenURIs[tokenId]);

        uint256 _newTokenId = genTokenId(string(_newUri));
        // remove sub tokenIds itself
        _subTokens[tokenId].remove(_newTokenId);

        if (bytes(_tokenURIs[_newTokenId]).length != 0) {
            delete _tokenURIs[_newTokenId];
        }

        super._burn(_newTokenId);
    }

    function subTokenIdCount(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId));
        return _subTokens[tokenId].length();
    }

    function subTokenIdByIndex(
        uint256 tokenId,
        uint256 index
    ) public view returns (uint256) {
        require(subTokenIdCount(tokenId) > index);
        return _subTokens[tokenId].at(index);
    }

    /**
     * End:Subdomain
     */

    /**
     * Begin: System
     */
    function genTokenId(string memory label) public pure returns (uint256) {
        require(bytes(label).length != 0);
        return uint256(keccak256(abi.encodePacked(label)));
    }

    function withdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * End: System
     */
    /**
     * Begin: working with metadata like: avatar, cover, email, phone, address, social ...
     */
    function set(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) {
        _set(key, value, tokenId);
    }

    function setMany(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) {
        _setMany(keys, values, tokenId);
    }

    function setByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) {
        _setByHash(keyHash, value, tokenId);
    }

    function setManyByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) {
        _setManyByHash(keyHashes, values, tokenId);
    }

    function reconfigure(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) {
        _reconfigure(keys, values, tokenId);
    }

    function reset(
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) {
        _reset(tokenId);
    }

    /**
     * End: metadata
     */

    function tokenByIndex(
        uint256 index
    ) external view override returns (uint256) {
        return 0;
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view override returns (uint256) {
        return 0;
    }

    function totalSupply() external view override returns (uint256) {
        return 0;
    }

    function getSubscriptionOwner() external view override returns (address) {
        // the owner of the subscription must be an EOA
        // Replace this with the account created in Step 1
        return owner();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(ISubscriptionOwner).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
