// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract LXDAOAnniversaryToken is ERC721AQueryable, AccessControl {
    bytes32 public constant OPERATION_ROLE = keccak256("OPERATION_ROLE");

    using Strings for uint256;

    string public metadataURI =
        "https://lxdao.io/metadata/LXDAO2ndAnniversaryNFT.json";
    uint256 public remainingMintAmount = 500;
    uint256 public remainingAirdropAmount = 100;
    uint256 public constant price = 0.01 ether;

    event MetadataURIChanged(
        address operator,
        string fromMetadataURI,
        string toMetadataURI
    );

    event Withdraw(address from, address to, uint256 amount);

    error CallFailed();

    constructor() ERC721A("LXDAO2ndAnniversaryNFT", "LXDAO2ndAT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATION_ROLE, msg.sender);
    }

    receive() external payable {}

    fallback() external payable {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC721A, ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(uint256 amount) external payable {
        require(amount <= remainingMintAmount, "Exceeded mint amount.");
        require(amount > 0, "The amount must greater than 0.");

        uint256 pay = price * amount;
        require(msg.value >= pay, "Insufficient payment.");

        remainingMintAmount = remainingMintAmount - amount;
        _safeMint(msg.sender, amount);
    }

    function airdrop(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyRole(OPERATION_ROLE) {
        require(
            receivers.length == amounts.length,
            "The length of accounts is not equal to amounts"
        );

        uint256 total = 0;
        for (uint256 i = 0; i < receivers.length; i++) {
            total = total + amounts[i];
        }
        require(remainingAirdropAmount >= total, "Exceeded airdrop amount.");

        remainingAirdropAmount = remainingAirdropAmount - total;
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], uint96(amounts[i]));
        }
    }

    function releaseAirdrop() external onlyRole(OPERATION_ROLE) {
        remainingMintAmount = remainingMintAmount + remainingAirdropAmount;
        remainingAirdropAmount = 0;
    }

    function updateMetadataURI(
        string calldata _newMetadataURI
    ) external onlyRole(OPERATION_ROLE) {
        emit MetadataURIChanged(msg.sender, metadataURI, _newMetadataURI);
        metadataURI = _newMetadataURI;
    }

    function withdraw(
        address payable to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to != address(0), "ZERO_ADDRESS");
        require(amount > 0, "Invalid input amount.");

        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to withdraw.");
        emit Withdraw(_msgSender(), to, amount);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId.");
        return metadataURI;
    }
}
