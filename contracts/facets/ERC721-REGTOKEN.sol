// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';


// basic librarz BASE64 will be moved to library contract
library Base64 {
  string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  bytes internal constant TABLE_DECODE =
    hex'0000000000000000000000000000000000000000000000000000000000000000'
    hex'00000000000000000000003e0000003f3435363738393a3b3c3d000000000000'
    hex'00000102030405060708090a0b0c0d0e0f101112131415161718190000000000'
    hex'001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';

    // load the table into memory
    string memory table = TABLE_ENCODE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';

    // load the table into memory
    string memory table = TABLE_ENCODE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        // read 3 bytes
        dataPtr := add(dataPtr, 3)
        let input := mload(dataPtr)

        // write 4 characters
        mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }

  function decode(string memory _data) internal pure returns (bytes memory) {
    bytes memory data = bytes(_data);

    if (data.length == 0) return new bytes(0);
    require(data.length % 4 == 0, 'invalid base64 decoder input');

    // load the table into memory
    bytes memory table = TABLE_DECODE;

    // every 4 characters represent 3 bytes
    uint256 decodedLen = (data.length / 4) * 3;

    // add some extra buffer at the end required for the writing
    bytes memory result = new bytes(decodedLen + 32);

    assembly {
      // padding with '='
      let lastBytes := mload(add(data, mload(data)))
      if eq(and(lastBytes, 0xFF), 0x3d) {
        decodedLen := sub(decodedLen, 1)
        if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
          decodedLen := sub(decodedLen, 1)
        }
      }

      // set the actual output length
      mstore(result, decodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 4 characters at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        // read 4 characters
        dataPtr := add(dataPtr, 4)
        let input := mload(dataPtr)

        // write 3 bytes
        let output := add(
          add(
            shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
            shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))
          ),
          add(
            shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
            and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
          )
        )
        mstore(resultPtr, shl(232, output))
        resultPtr := add(resultPtr, 3)
      }
    }

    return result;
  }
}
// basic SVG generator for NFT img
library SvgGenerator {
  function generateSvg(string memory attributes) internal pure returns (string memory) {
    return string(abi.encodePacked('<svg ', attributes, '></svg>'));
  }
}
// read intefade for valhallaToken 
interface ValhallaToken {
  function balanceOf(address account) external view returns (uint256);
}

contract GTurnPlayer is ERC721, Ownable, Pausable {
  // Gotchi and Valhalla planets allow to mint twice
  address internal GOTCHI_CONTRACT = address(bytes20(hex'86935F11C86623deC8a25696E1C19a8659CbF95d'));
  ERC721 public erc721ContractGotchi = ERC721(GOTCHI_CONTRACT);
  address internal VALHALLA_CONTRACT = address(bytes20(hex'9724fdf5ae41570decc2d3094c65eafa7e1ab7d4'));
  ERC20 public erc20ContractValhalla = ERC20(VALHALLA_CONTRACT);

  // min mint price 
  uint256 private MINT_COST = 3 ether;

  // public constants
  address public contractOwner;
  string public versions;
  uint256 public totalSupply;
  // string public AAVEGOTCHI_CONTRACT = '0x86935f11c86623dec8a25696e1c19a8659cbf95d';
  //mapping(uint256 => bool) private _transferable;
  mapping(address => bool) internal _hasPlayer;
  mapping(uint256 => string) internal _tokenURIs;
  // define using
  using Strings for uint256;
  using Base64 for bytes;
  // Base storage setup
  struct Player {
    uint256 id;
    string name;
    address owner;
    address mintedBy;
    string discord;
    uint256 attack;
    uint256 defense;
    uint256 magic;
    uint256 economy;
    uint256 xp;
    uint256 lvl;
    string version;
  }
  Player[] internal players;
  // default OpenSea tokenUri formating
  struct Attribute {
    string trait_type;
    string value;
  }
  struct PlayerAttributes {
    string name;
    string image_data;
    Attribute[] attributes;
  }


  constructor(address achritect) ERC721('GTurnPlayer', 'GTP')  {
    versions = '0.0.0';
    contractOwner = achritect;
    _transferOwnership(contractOwner);
    
    
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

function destroy() external  onlyOwner {
        selfdestruct(payable(contractOwner));
    }
  // only one mint per wallet
  modifier onlyOnePlayerPerOwner() {
    uint256 balance = balanceOf(msg.sender);
    require(!_hasPlayer[msg.sender], 'You can only mint one player per owner.');
    require(balance < 1, 'You can only mint one player per owner.');
    _;
  }
  // Only Gotchi owner
  modifier onlyERC721GotchiOwner() {
    require(
      erc721ContractGotchi.balanceOf(msg.sender) > 0,
      'Only the owner of an ERC721 Aavegotchi token on the specified contract can perform this action'
    );
    _;
  }
  // Only DF planet owner
  modifier onlyERC20ValhallaOwner() {
    require(
      erc20ContractValhalla.balanceOf(msg.sender) > 0,
      'Only the owner of an ERC721 token on the specified contract can perform this action'
    );
    _;
  }

  // modifier onlyOwnerOfAavegotchi() {
  //   bool owner = false;
  //   for (uint i = 0; i < getTotalSupply(); i++) {
  //     if (ownerOfAavegotchi(i) == msg.sender) {
  //       owner = true;
  //       break;
  //     }
  //   }
  //   require(owner == true, 'You are not the owner of any Aavegotchi token.');
  //   _;
  // }

  // modifier onlyOwnerOfPlayer(uint256 playerId) {
  //   require(playerId > 0 && playerId <= players.length, 'Invalid player ID.');
  //   Player storage player = players[playerId - 1];
  //   require(player.owner == msg.sender, 'You are not the owner of this player.');
  //   _;
  // }

   // Main svg function for NFT 
  function getSvg() private pure returns (string memory) {
    string memory svg;
    svg = "<svg width='350px' height='350px' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'> <path d='M11.55 18.46C11.3516 18.4577 11.1617 18.3789 11.02 18.24L5.32001 12.53C5.19492 12.3935 5.12553 12.2151 5.12553 12.03C5.12553 11.8449 5.19492 11.6665 5.32001 11.53L13.71 3C13.8505 2.85931 14.0412 2.78017 14.24 2.78H19.99C20.1863 2.78 20.3745 2.85796 20.5133 2.99674C20.652 3.13552 20.73 3.32374 20.73 3.52L20.8 9.2C20.8003 9.40188 20.7213 9.5958 20.58 9.74L12.07 18.25C11.9282 18.3812 11.7432 18.4559 11.55 18.46ZM6.90001 12L11.55 16.64L19.3 8.89L19.25 4.27H14.56L6.90001 12Z' fill='red'/> <path d='M14.35 21.25C14.2512 21.2522 14.153 21.2338 14.0618 21.1959C13.9705 21.158 13.8882 21.1015 13.82 21.03L2.52 9.73999C2.38752 9.59782 2.3154 9.40977 2.31883 9.21547C2.32226 9.02117 2.40097 8.83578 2.53838 8.69837C2.67579 8.56096 2.86118 8.48224 3.05548 8.47882C3.24978 8.47539 3.43783 8.54751 3.58 8.67999L14.88 20C15.0205 20.1406 15.0993 20.3312 15.0993 20.53C15.0993 20.7287 15.0205 20.9194 14.88 21.06C14.7353 21.1907 14.5448 21.259 14.35 21.25Z' fill='red'/> <path d='M6.5 21.19C6.31632 21.1867 6.13951 21.1195 6 21L2.55 17.55C2.47884 17.4774 2.42276 17.3914 2.385 17.297C2.34724 17.2026 2.32855 17.1017 2.33 17C2.33 16.59 2.33 16.58 6.45 12.58C6.59063 12.4395 6.78125 12.3607 6.98 12.3607C7.17876 12.3607 7.36938 12.4395 7.51 12.58C7.65046 12.7206 7.72934 12.9112 7.72934 13.11C7.72934 13.3087 7.65046 13.4994 7.51 13.64C6.22001 14.91 4.82 16.29 4.12 17L6.5 19.38L9.86 16C9.92895 15.9292 10.0114 15.873 10.1024 15.8346C10.1934 15.7962 10.2912 15.7764 10.39 15.7764C10.4888 15.7764 10.5866 15.7962 10.6776 15.8346C10.7686 15.873 10.8511 15.9292 10.92 16C11.0605 16.1406 11.1393 16.3312 11.1393 16.53C11.1393 16.7287 11.0605 16.9194 10.92 17.06L7 21C6.8614 21.121 6.68402 21.1884 6.5 21.19Z' fill='red'/> </svg>";
    return svg;
  }

  // basic withdraw - need to be apply epocha limitation and split for first empires
  function withdrawEther() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'No Ether to withdraw');

    (bool success, ) = payable(msg.sender).call{ value: balance }('');
    require(success, 'Matic Ether failed');
  }
  // basic get player by ID
  function getPlayer(
    uint256 playerId
   )
    public
    view
    returns (
      uint256 id,
      string memory name,
      address owner,
      address mintedBy,
      string memory discord,
      uint256 attack,
      uint256 defense,
      uint256 magic,
      uint256 economy,
      uint256 xp,
      uint256 lvl,
      string memory version
    )
    {
    require(playerId > 0 && playerId <= players.length, 'Invalid player ID.');

    Player memory player = players[playerId - 1]; // player IDs start from 1, so subtract 1 to get the correct index

    id = player.id;
    name = player.name;
    owner = player.owner;
    mintedBy = player.mintedBy;
    discord = player.discord;
    attack = player.attack;
    defense = player.defense;
    magic = player.magic;
    economy = player.economy;
    xp = player.xp;
    lvl = player.lvl;
    version = player.version;
  }
  // Mint new player
  function buy_New_Player(string memory _name, string memory _discord) public payable onlyOnePlayerPerOwner {
    require(msg.value == (MINT_COST), '"You must send a 3 matic value with this transaction."');

    // Increment the player count
    uint256 playerId = players.length + 1;

    // Generate random attack and defense stats
    
    // Create a new player struct
    Player memory newPlayer = Player({
      id: playerId,
      name: _name,
      owner: msg.sender,
      mintedBy: msg.sender,
      discord: _discord,
      attack:  generateRandomStat(playerId, 'attack'),
      defense: generateRandomStat(playerId, 'defense'),
      magic: generateRandomStat(playerId, 'magic'),
      economy: generateRandomStat(playerId, 'economy'),
      xp: 0,
      lvl: 0,
      version: '0.0.0'
    });

    // Add the new player to the players array
    players.push(newPlayer);

    // Mark that the owner has a player
    _hasPlayer[msg.sender] = true;

    // Set the token URI for the newly minted token
    mintERC721Player(msg.sender, playerId);
  }

  // function aavegotchi_New_Player(
  //   string memory _name,
  //   string memory _discord
  // ) public onlyOwnerOfAavegotchi onlyOnePlayerPerOwner {
  //   // Increment the player count
  //   uint256 playerId = players.length + 1;
  //   // Generate random attack and defense stats
  //   uint256 _attack = generateRandomStat(playerId, 'attack');
  //   uint256 _defense = generateRandomStat(playerId, 'defense');
  //   // Create a new player struct
  //   Player memory newPlayer = Player({
  //     id: playerId,
  //     name: _name,
  //     owner: msg.sender,
  //     mintedBy: msg.sender,
  //     discord: _discord,
  //     attack: _attack,
  //     defense: _defense,
  //     xp: 0,
  //     lvl: 0,
  //     version: '0.0.0'
  //   });

  //   // Add the new player to the players array
  //   players.push(newPlayer);

  //   // Mark that the owner has a player
  //   _hasPlayer[msg.sender] = true;

  //   // Set the token URI for the newly minted token
  //   mintERC721Player(msg.sender, playerId);
  // }
 
  // internal function mint ERC721 and generate URI according that
  function mintERC721Player(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId);
    Player memory player = players[tokenId - 1];
    // JSON string prepation
    string memory json = string(
      abi.encodePacked(
        '{"name": "',
        player.name,
        '",',
        '"image_data": "',
        getSvg(),
        '",',
        '"attributes": [{"trait_type": "discord", "value": ',
        player.discord,
        '},',
        '{"trait_type": "attack", "value": ',
        uint256ToString(player.attack),
        '},',
        '{"trait_type": "defense", "value": ',
        uint256ToString(player.defense),
        '},',
        '{"trait_type": "lvl", "value": ',
        uint256ToString(player.lvl),
        '},',
        '{"trait_type": "xp", "value": ',
        uint256ToString(player.xp),
        '},',
        '{"trait_type": "version", "value": ',
        player.version,
        '"}',
        ']}'
      )
    );
    string memory uri = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    totalSupply++;
    _setTokenURI(tokenId, uri);
  }

  // Helper function to generate a random stat
  function generateRandomStat(uint256 playerId, string memory statType) private view returns (uint256) {
    bytes32 hash = keccak256(abi.encodePacked(playerId + 1000, statType, block.timestamp));
    return (uint256(hash) % 50) + 1; // Random number between 1-100
  }
  // basic function to check if sender minted
  function isPlayerMintedBySender() public view returns (bool) {
    for (uint256 i = 0; i < players.length; i++) {
      Player memory player = players[i];
      if (player.mintedBy == msg.sender) {
        return true;
      }
    }
    return false;
  }
  // basic function to read token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return _tokenURIs[tokenId];
  }
  // basic function to set token URI
  function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
    require(_exists(tokenId), 'ERC721Metadata: URI set of nonexistent token');
    _tokenURIs[tokenId] = uri;
  }

  // basic function to get total supply ERC721
  function getTotalSupply() public view returns (uint256) {
    return totalSupply;
  }
  // basic function to butn ERC721
  function _burn(uint256 tokenId) internal override (ERC721) {
    super._burn(tokenId);
  }
  // basic function to convert uint256 to string
  function uint256ToString(uint256 value) internal pure returns (string memory) {
    // Special case zero value
    if (value == 0) {
      return '0';
    }
    // Calculate length of uint256 value
    uint256 length = 0;
    for (uint256 i = value; i > 0; i /= 10) {
      length++;
    }
    // Allocate string buffer
    bytes memory buffer = new bytes(length);
    // Convert uint256 to string
    for (uint256 i = length; i > 0; i--) {
      buffer[i - 1] = bytes1(uint8(48 + (value % 10)));
      value /= 10;
    }
    return string(abi.encodePacked(buffer));
  }
}

contract GTurnPlayerProxy is TransparentUpgradeableProxy {
  constructor(
    address logic,
    address admin,
    bytes memory data
  ) payable TransparentUpgradeableProxy(logic, admin, data) {}


}
