// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PetBase.sol";
import "./Cooldowns.sol";

contract PetOwnership is ERC721Enumerable, Ownable, Cooldowns {
    using PetBase for PetBase.Pet;

    PetBase.Pet[] public pets;

    constructor() ERC721("PetOwnership", "PET") {}

    function createPet(uint256 _genes) external onlyOwner {
        uint256 newPetId = pets.length;
        uint8 color = uint8(_genes & 0xFF);
        uint8 size = uint8((_genes >> 8) & 0xFF);
        uint8 pattern = uint8((_genes >> 16) & 0xFF);

        PetBase.Pet memory _newPet = PetBase.Pet({
            genes: _genes,
            color: color,
            size: size,
            pattern: pattern,
            birthTime: uint64(block.timestamp),
            matronId: 0,
            sireId: 0,
            generation: 0,
            cooldownEndBlock: 0
        });

        pets.push(_newPet);
        _mint(msg.sender, newPetId);
    }


    function breed(uint256 _matronId, uint256 _sireId) public {
        require(_owns(msg.sender, _matronId), "Caller does not own the matron pet");
        require(_owns(msg.sender, _sireId), "Caller does not own the sire pet");

        PetBase.Pet storage matron = pets[_matronId];
        PetBase.Pet storage sire = pets[_sireId];

        require(matron.isReadyToBreed(), "Matron pet is not ready to breed");
        require(sire.isReadyToBreed(), "Sire pet is not ready to breed");
        require(matron.canBreedWith(sire), "Pets cannot breed with each other");

        uint256 newPetId = pets.length;
        uint32[] memory _cooldowns = _getCooldowns();
        PetBase.Pet memory newPet = matron.giveBirth(sire, newPetId, _cooldowns);
        pets.push(newPet);

        _mint(msg.sender, newPetId);
    }

    function getPet(uint256 _petId) public view returns (
        uint256 genes,
        uint64 birthTime,
        uint32 matronId,
        uint32 sireId,
        uint16 generation,
        uint64 cooldownEndBlock
    ) {
        PetBase.Pet storage pet = pets[_petId];
        genes = pet.genes;
        birthTime = pet.birthTime;
        matronId = pet.matronId;
        sireId = pet.sireId;
        generation = pet.generation;
        cooldownEndBlock = pet.cooldownEndBlock;
    }

    function _getCooldowns() internal view returns (uint32[] memory) {
        uint32[] memory _cooldowns = new uint32[](cooldowns.length);
        for (uint256 i = 0; i < cooldowns.length; i++) {
            _cooldowns[i] = cooldowns[i];
        }
        return _cooldowns;
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ownerOf(_tokenId) == _claimant;
    }
}
