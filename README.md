# Factoriopedia Extended

A Factorio mod that adds custom simulations to factoriopedia.

## Features
The mod is in early development, so a lot of pages are missing.

Expanded pages:
- Landfill
- Logistic chests
- Inserters
- Mining drills

## Compatibility
Where doable, custom simulations support modded entities within the expanded categories.
However, it can't account for all possibilities.
The main goal is to support vanilla and Space Age content, but issue reports about
broken modded simulations are welcome (although not guaranteed to be resolved quickly).

*This will have a list of verified compatible content mods 
or mods with explicit compatibility when there are any.*

## Contributing
This section is a general guideline to the code and simulation style to keep it consistent.

Simulations:
- Simulations should convey the functionality of the entity/item/etc.
- Simulations should form a seamless loop.
- Simulation camera location should be at `{0.5, 0}` for odd-sized entities and `{0, 0}` for even-sized.
  (can be done with `environment.center_viewport()`)
- Simulations should take compatibility with different entity configurations into account when reasonable.

Code:
- Simulation scripts must be stored in `simulations/` directory and registered in `control.lua`.
- Simulated entries must be registered in `data-updates.lua`.
- Simulations should use functionality provided by `library/environment.lua` when applicable.
- Simulations should use the event system provided by `library/story.lua` when applicable.
- Simulation entities use the `"enemy"` force. (in most cases, that is the default)

## Integration
Other mods are encouraged to provide simulations for their content.
As a creator, you can create an optional dependency on Factoriopedia Extended to use
the event system and existing toolkit, or copy the required code.

You can also submit a pull request to add simulations for your mod.