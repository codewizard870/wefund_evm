// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BaseContract {
    struct OnChainMetadata {
        string category;
        string subCategory;
    }
    struct RoleSerialization{
        string name;
        string[] permission;
        address[] members;
    }
    struct Role {
        string name;
        mapping(string => bool) permission;
        address[] members;
    }
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}
