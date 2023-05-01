pragma solidity ^0.8.0;

library PetBase {
    struct Pet {
        uint256 genes;
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

    function _computeCooldown(Pet storage _pet, uint32[] memory _cooldowns) internal view returns (uint32) {
        uint32 cooldownIndex = _pet.generation / 2;
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }
        return _cooldowns[cooldownIndex];
    }

    function breed(Pet storage _matron, Pet storage _sire) internal view returns (uint256) {
        // Implement breeding logic to generate new pet genes
        uint256 newGenes = uint256(keccak256(abi.encodePacked(_matron.genes, _sire.genes, block.timestamp)));

        return newGenes;
    }

    function giveBirth(Pet storage _matron, Pet storage _sire, uint256 _newPetId, uint32[] memory _cooldowns) internal returns (Pet memory) {
        uint16 parentGeneration = _matron.generation;
        if (_sire.generation > _matron.generation) {
            parentGeneration = _sire.generation;
        }

        uint256 childGenes = breed(_matron, _sire);

        Pet memory newPet = Pet({
            genes: childGenes,
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
