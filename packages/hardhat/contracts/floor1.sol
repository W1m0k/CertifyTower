// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Floor1 {
    function climbing(string calldata _data) external pure returns (bool) {
        uint256 test1 = uint256(
            keccak256(abi.encodePacked("My name is : ", _data))
        );

        //console.log("test1 %d", test1);

        require(test1 % 222 > 77, "failed"); //test
        return true;
    }
}
