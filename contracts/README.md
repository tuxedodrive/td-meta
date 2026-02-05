# Shared Contracts

This directory is for API contracts and schemas shared between multiple TuxedoDrive repositories.

## Important: When NOT to Use This Directory

Per [ADR-028: Enemy Testing Contract Sharing](https://github.com/tuxedodrive/td-core/blob/main/docs/adr/028-enemy-testing-contract-sharing.md), **most contracts should live in the repository that owns the API**, not here.

For example:
- td-core owns its API contracts
- td-edge fetches contracts from td-core during CI
- Contracts live in `td-core/test/enemy_test_data/contracts/`

## When to Use This Directory

Only centralize contracts here when:

1. No single repository clearly owns the contract
2. The contract represents a truly shared protocol between multiple services
3. Multiple repositories need to both produce AND consume against the same contract
4. Centralizing provides clear organizational benefits that outweigh ownership clarity

## Current Approach

As of now, most inter-repository contracts follow the pattern from ADR-028:

- **Owner repository** defines the contract
- **Consumer repositories** fetch the contract during CI
- **CI fails** if contract drift is detected

This keeps contracts close to the code that defines them while still catching drift automatically.

## Future Considerations

If the number of shared contracts grows significantly or the ownership model becomes unclear, we may revisit centralizing some contracts here. Any such change should be documented in a cross-repo ADR in `docs/adr/`.

## References

- [ADR-028: Enemy Testing Contract Sharing](https://github.com/tuxedodrive/td-core/blob/main/docs/adr/028-enemy-testing-contract-sharing.md)
- td-core contracts: `td-core/test/enemy_test_data/contracts/`
