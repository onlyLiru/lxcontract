// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract LXDAOAnniversaryToken is ERC721AQueryable, AccessControl {
    bytes32 public constant OPERATION_ROLE = keccak256("OPERATION_ROLE");

    using Strings for uint256;

    string public baseURI;
    string public metadataURI =
        "https://lxdao.io/metadata/LXDAO2stAnniversaryNFT.json";
    uint256 public remainingMintAmount = 500;
    uint256 public remainingAirdropAmount = 100;
    uint256 public constant price = 0 ether;

    event BaseURIChanged(
        address operator,
        string fromBaseURI,
        string toBaseURI
    );

    event MetaURIChanged(
        address operator,
        string fromMetaURI,
        string toMetaURI
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

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }

    function mint(uint256 amount) external payable {
        require(amount <= remainingMintAmount, "Exceeded mint amount.");
        require(amount > 0, "the amount must greater then 0.");

        uint256 pay = price * amount;

        require(msg.value >= pay, "Insufficient payment.");

        remainingMintAmount = remainingMintAmount - amount;

        _safeMint(msg.sender, amount);

        // refund dust eth, if any
        if (msg.value > pay) {
            safeTransferETH(msg.sender, msg.value - pay);
        }
    }

    function airdrop(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyRole(OPERATION_ROLE) {
        require(
            receivers.length == amounts.length,
            "the length of accounts is not equal to amounts"
        );

        uint256 total = 0;
        for (uint256 i = 0; i < receivers.length; i++) {
            total = total + amounts[i];
        }
        require(remainingAirdropAmount >= total, "Exceeded airdrop amount.");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], uint96(amounts[i]));
        }

        remainingAirdropAmount = remainingAirdropAmount - total;
    }

    function releaseAirdrop() external onlyRole(OPERATION_ROLE) {
        remainingMintAmount = remainingMintAmount + remainingAirdropAmount;
        remainingAirdropAmount = 0;
    }

    function updateMetaURI(
        string calldata _newMetaURI
    ) external onlyRole(OPERATION_ROLE) {
        emit MetaURIChanged(msg.sender, metadataURI, _newMetaURI);
        metadataURI = _newMetaURI;
    }

    function withdrawToken(
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(to != address(0), "ZERO_ADDRESS");
        require(amount > 0, "Invalid input amount.");

        // transfer
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert CallFailed();
        }
        emit Withdraw(_msgSender(), to, amount);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Invalid tokenId.");
        return metadataURI;
    }
}
