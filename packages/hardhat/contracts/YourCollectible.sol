pragma solidity 0.8.13;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./ToColor.sol";

interface ITower {
    // ## Have chance to drop rare item
    //function floorUp(uint256 _tokenID) external view returns (bool);

    function climbing(string calldata _data) external returns (bool);
}

contract YourCollectible is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint160;
    using ToColor for bytes3;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public price = 1 ether;

    constructor() ERC721("Certify Tower", "CTW") {}

    mapping(uint256 => bytes3) public color;
    //mapping(uint256 => uint256) public chubbiness; //check
    mapping(address => uint256) floor;
    mapping(uint256 => address) floorAddr;

    function setfloorAddr(uint256 _floor, address _addr) public onlyOwner {
        // set public and community vote for next floor
        floorAddr[_floor] = _addr;
    }

    function climb(uint256 _floor, string calldata _data) public payable {
        require(msg.value == price, "invalid payment");
        require(floor[msg.sender] + 1 == _floor, "invalid floor");
        require(floorAddr[_floor] != address(0), "unavailable");

        if (ITower(floorAddr[_floor]).climbing(_data)) {
            floor[msg.sender] = _floor;
            if (floor[msg.sender] == 1) {
                _tokenIds.increment();
                uint256 id = _tokenIds.current();
                _mint(msg.sender, id);

                bytes32 predictableRandom = keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        msg.sender,
                        address(this),
                        id
                    )
                );
                color[id] =
                    bytes2(predictableRandom[0]) |
                    (bytes2(predictableRandom[1]) >> 8) |
                    (bytes3(predictableRandom[2]) >> 16);
                //chubbiness[id] =
                //    35 +
                //    ((55 * uint256(uint8(predictableRandom[3]))) / 255);
            }
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "not exist");
        string memory name = string(
            abi.encodePacked("Loogie #", id.toString())
        );
        string memory description = string(
            abi.encodePacked(
                "This Loogie is the color #",
                color[id].toColor(),
                " with a floor of ",
                //chubbiness[id].toString(),
                floor[ownerOf(id)].toString(),
                "!!!"
            )
        );
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":"',
                                    name,
                                    '", "description":"',
                                    description,
                                    //'", "external_url":"https://burnyboys.com/token/',
                                    //id.toString(),
                                    '", "attributes": [{"trait_type": "color", "value": "#',
                                    color[id].toColor(),
                                    '"},{"trait_type": "floor", "value": ',
                                    //chubbiness[id].toString(),
                                    floor[ownerOf(id)].toString(),
                                    '}], "owner":"',
                                    (uint160(ownerOf(id))).toHexString(20),
                                    '", "image": "',
                                    "data:image/svg+xml;base64,",
                                    image,
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function generateSVGofTokenById(uint256 id)
        internal
        view
        returns (string memory)
    {
        string memory svg = string(
            abi.encodePacked(
                '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
                renderTokenById(id),
                "</svg>"
            )
        );

        return svg;
    }

    // Visibility is `public` to enable it being called by other contracts for composition.
    function renderTokenById(uint256 id) public view returns (string memory) {
        string memory render = string(
            abi.encodePacked(
                '<g id="eye1">',
                '<ellipse stroke-width="3" ry="29.5" rx="29.5" id="svg_1" cy="154.5" cx="181.5" stroke="#000" fill="#fff"/>',
                '<ellipse ry="3.5" rx="2.5" id="svg_3" cy="154.5" cx="173.5" stroke-width="3" stroke="#000" fill="#000000"/>',
                "</g>",
                '<g id="head">',
                '<ellipse fill="#',
                color[id].toColor(),
                '" stroke-width="3" cx="204.5" cy="211.80065" id="svg_5" rx="',
                //chubbiness[id].toString(),
                floor[ownerOf(id)].toString(),
                '" ry="51.80065" stroke="#000"/>',
                "</g>",
                '<g id="eye2">',
                '<ellipse stroke-width="3" ry="29.5" rx="29.5" id="svg_2" cy="168.5" cx="209.5" stroke="#000" fill="#fff"/>',
                '<ellipse ry="3.5" rx="3" id="svg_4" cy="169.5" cx="208" stroke-width="3" fill="#000000" stroke="#000"/>',
                "</g>"
            )
        );

        return render;
    }
}