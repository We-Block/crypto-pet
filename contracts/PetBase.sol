// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PetBase {
    struct Pet {
    uint256 genes;
    uint8 color;
    uint8 size;
    uint8 pattern;
    uint64 birthTime;
    uint32 matronId;
    uint32 sireId;
    uint16 generation;
    uint64 cooldownEndBlock;
    }


    function isReadyToBreed(Pet storage _pet) public view returns (bool) {
        return (_pet.cooldownEndBlock <= block.number);
    }

    function canBreedWith(Pet storage _pet, Pet storage _otherPet) public view returns (bool) {
        return (_pet.matronId != _otherPet.matronId) && (_pet.sireId != _otherPet.sireId);
    }

    function _computeCooldown(Pet memory _pet, uint32[] memory _cooldowns) internal view returns (uint32) {
        uint32 cooldownIndex = _pet.generation / 2;
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }
        return _cooldowns[cooldownIndex];
    }


    function breed(Pet storage _matron, Pet storage _sire) internal view returns (uint256) {
    // Extract specific attributes from matron and sire genes (e.g., color, size, pattern)
    uint256 matronColor = _matron.genes & 0xFF;
    uint256 sireColor = _sire.genes & 0xFF;

    uint256 matronSize = (_matron.genes >> 8) & 0xFF;
    uint256 sireSize = (_sire.genes >> 8) & 0xFF;

    uint256 matronPattern = (_matron.genes >> 16) & 0xFF;
    uint256 sirePattern = (_sire.genes >> 16) & 0xFF;

    // Implement breeding logic for each attribute
    uint256 childColor = _combineAttributes(matronColor, sireColor);
    uint256 childSize = _combineAttributes(matronSize, sireSize);
    uint256 childPattern = _combineAttributes(matronPattern, sirePattern);

    // Combine child attributes back into the new genes
    uint256 newGenes = (childColor | (childSize << 8) | (childPattern << 16));

    // Mix in a random factor to introduce mutations
    uint256 randomFactor = uint256(keccak256(abi.encodePacked(_matron.genes, _sire.genes, block.timestamp))) & 0xFFFFFF;
    newGenes = newGenes ^ randomFactor;

    return newGenes;
}

    function _combineAttributes(uint256 _attr1, uint256 _attr2) internal pure returns (uint256) {
        // Example logic for combining attributes: take an average, but favor the higher attribute
        uint256 combined = (_attr1 + _attr2) / 2;

        if (_attr1 > _attr2) {
            combined += _attr1 % 2;
        } else {
            combined += _attr2 % 2;
        }

        return combined;
    }


    function giveBirth(Pet storage _matron, Pet storage _sire, uint256 _newPetId, uint32[] memory _cooldowns) internal returns (Pet memory) {
        uint16 parentGeneration = _matron.generation;
        if (_sire.generation > _matron.generation) {
            parentGeneration = _sire.generation;
        }

        uint256 childGenes = breed(_matron, _sire);
        uint8 childColor = uint8(childGenes & 0xFF);
        uint8 childSize = uint8((childGenes >> 8) & 0xFF);
        uint8 childPattern = uint8((childGenes >> 16) & 0xFF);

        Pet memory newPet = Pet({
            genes: childGenes,
            color: childColor,
            size: childSize,
            pattern: childPattern,
            birthTime: uint64(block.timestamp),
            matronId: uint32(_matron.matronId),
            sireId: uint32(_sire.sireId),
            generation: parentGeneration + 1,
            cooldownEndBlock: 0
        });

        newPet.cooldownEndBlock = uint64(block.number + _computeCooldown(newPet, _cooldowns));

        return newPet;
    }

}
