# Open source reimplementation of MDK in Godot

This project aims to reimplement [MDK](https://en.wikipedia.org/wiki/MDK_(video_game)
using [Godot Engine](https://godotengine.org/). **It is not in a playable state yet.**

This is being developed as a personal project for several reasons:

- Allow MDK to run on modern systems easily, on any platform.
  No compatibility wrappers needed.
- Enhance the game in ways that were not possible beforehand: uncapped framerate,
  replayability options, quality of life features, …
- Give me another "real world" Godot project to work on :slightly_smiling_face:

___

**Help is needed for reverse engineering file formats!**
This reverse engineering effort is required to make the game playable.
If you have experience with reverse engineering (especially 3D file formats),
feel free to chime in the [GitHub issue tracker](https://github.com/Calinou/godot-mdk/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22).

___

## Running the project

Running the project **requires** game data from a MDK installation.
You can buy the original game on [GOG](https://www.gog.com/game/mdk)
or [Steam](https://store.steampowered.com/app/38450/MDK/).
*Waiting for a sale?* Set up an email alert using [IsThereAnyIdeal](https://isthereanydeal.com/game/mdk/info/).

Several file formats from the game have been reverse engineered for interoperability
purposes. This allows the game to run without having to convert game data manually
(and without redistributing it within this repository).

The project currently does not require game data from MDK to be opened in the editor,
but this may change in the future (at least for level scenes).

## License

Copyright © 2021 Hugo Locurcio and contributors

Unless otherwise specified, files in this repository are licensed under the MIT license.
See [LICENSE.md](LICENSE.md) for more information.

This repository does not include any proprietary game data from MDK.

*This project is not affiliated with Shiny Entertainment or Interplay Inc.*
