// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

error ERC721__NotMinted(uint256 id);
error ERC721__AlreadyMinted(uint256 id);
error ERC721__ZeroAddress();
error ERC721__NotAuthorized();
error ERC721__UnsafeRecipient(address recipient);
error ERC721__InvalidRecipient();

abstract contract ERC721 {
    /* ----------events---------- */

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /* ----------state variables---------- */

    /* ----------metadata---------- */
    string public name;
    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /* ----------balance / owner storage---------- */
    mapping(uint256 => address) internal _ownerOf;
    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _ownerOf[id];

        if (owner == address(0)) {
            revert ERC721__NotMinted(id);
        }
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721__ZeroAddress();
        }

        return _balanceOf[owner];
    }

    /* ----------approval---------- */
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /* ----------constructor---------- */
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /* ----------ERC721 logic---------- */
    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        if (msg.sender != owner || !isApprovedForAll[owner][msg.sender]) {
            revert ERC721__NotAuthorized();
        }

        getApproved[id] = spender;
        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (from != _ownerOf[id]) {
            revert ERC721__NotAuthorized();
        }
        if (to == address(0)) {
            revert ERC721__InvalidRecipient();
        }

        if (
            msg.sender != from ||
            !isApprovedForAll[from][msg.sender] ||
            msg.sender != getApproved[id]
        ) {
            revert ERC721__NotAuthorized();
        }

        // underflow and overflow is impossible since we already check for the ownership
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    // used to check if the address received the token is ERC721Receiver compatible or not, just to ensure that the NFT doesn't get locked up in an address
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 ||
            ERC721TokenReceiver(to).onERC721Received(
                msg.sender,
                from,
                id,
                ""
            ) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) {
            revert ERC721__UnsafeRecipient(to);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 ||
            ERC721TokenReceiver(to).onERC721Received(
                msg.sender,
                from,
                id,
                data
            ) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) {
            revert ERC721__UnsafeRecipient(to);
        }
    }

    /* ----------ERC165---------- */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ----------mint/burn logic----------*/
    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) {
            revert ERC721__InvalidRecipient();
        }
        if (_ownerOf[id] != address(0)) {
            revert ERC721__AlreadyMinted(id);
        }

        // overflow not possible
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if (owner == address(0)) {
            revert ERC721__NotMinted(id);
        }

        // underflow not possible
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];
        delete getApproved[id];
        emit Transfer(owner, address(0), id);
    }

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 ||
            ERC721TokenReceiver(to).onERC721Received(
                msg.sender,
                address(0),
                id,
                ""
            ) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) {
            revert ERC721__UnsafeRecipient(to);
        }
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 ||
            ERC721TokenReceiver(to).onERC721Received(
                msg.sender,
                address(0),
                id,
                data
            ) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) {
            revert ERC721__UnsafeRecipient(to);
        }
    }
}

abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
