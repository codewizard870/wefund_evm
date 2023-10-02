// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DAO {

    using Strings for string;
    using Counters for Counters.Counter;

    /******* GLOBAL VARIABLES ********/
    
    address[] private daoAddresses;
    uint256 constant MAX_APPROVERS = 3; 

    /******* ENUMS ********/

    enum DAOStatus {
        Live,
        Split,
        Deregistered, 
        Purged
    }

    enum PrivacyStatus {
        Anonymous,
        IDVerified
    }

    enum AdminRights {
        ANY_ONE,
        FIRST_AND_SECOND,
        FIRST_AND_THIRD,
        SECOND_AND_THIRD,
        MAJORITY,
        ALL
    }

    enum NotifiedPartyAccess {
        NoAccess,
        ViewDAORecord,
        ViewOwnerUsernames,
        ViewOwnerIdInformation,
        AccessUploadedDocuments
    }

    /******* MAPPINGS ********/

    mapping(address => DAOData) private daos;

    mapping(bytes4 => AdminRights) public functionApprovers;

    mapping(bytes32 => mapping(address => bool)) public approvals;

    mapping(address => bool) public isAdministrator;

    mapping(address => bool) public authorizedRegistrars;

    /******* STRUCTS ********/

    struct Administrator {
        address adminAddress;
        bool verificationRequested;
        bool verified;
    }
        
    struct Owner {
        address ownerAddress;
        uint256 ownerShares;
        bool verificationRequested;
        bool verified;
    }
    
    struct NotificationParty {
        address notificationPartyAddress;
        string[] notificationPartyAccess;
        bool verified;
    }

    struct Agent {
        string agentName;
        string agentAddress;
        string agentTelephone;
        string agentEmail;
    }
    
    struct DAOData {
        string daoName;
        address creator;
        string status;
        string privacyStatus;
        bool documentsFiled;
        bool hasAgent;
        Agent agent;
        Administrator[] administrators;
        string adminRights;
        bool hasOwners;
        Owner[] owners;
        bool hasNotificationParties;
        NotificationParty[] notificationParties;
        address[] identityVerificationRequests;
        uint256 expiryDate;
        uint256 createdAt;
        uint256 updatedAt;
        bool archived;
        uint256 archivedAt;
    }

    struct DAOInfo {
        address daoAddress;
        string role;
    }

    

    // Register a DAO
    function registerDAO(
        string memory _daoName,
        bool _documentsFiled,
        bool _hasAgent,
        // Agent memory _agent,
        address[] memory _administratorAddresses,
        string memory _adminRights,
        bool _hasOwners,
        address[] memory _ownerAddresses,
        uint256[] memory _ownerShares,
        bool _hasNotificationParties,
        address[] memory _notificationPartyAddresses,
        // string[][] memory _notificationPartyAccess,
        address[] memory _identityVerificationRequests,
        uint256 _expiryDate
    ) public 
    {

    }

}