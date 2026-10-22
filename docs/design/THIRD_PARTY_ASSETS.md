# Third-Party Asset Manifest

Track every external asset used in production. Do not assume an entire website has one license; record the exact pack/model and license at time of acquisition.

| Asset / Pack | Creator | Source | License | Modified? | Project Path | Notes |
|---|---|---|---|---|---|---|
| Quaternius : Stylized Nature MegaKit (Standard, free edition), 31-model subset | Quaternius | quaternius.itch.io/stylized-nature-megakit (free download; zip sha256 298f6732b872…) | CC0 1.0 (License_Standard.txt kept) | Textures over 1024 px downscaled to 1024; geometry unmodified | `assets/third_party/quaternius/stylized_nature_standard/` | Trees, pines, twisted trees, bushes, ferns, grass, flowers, mushrooms, rocks, stepping stones. Foliage tinted at runtime to match the palette. |
| Other Quaternius packs | Quaternius | TBD | Verify exact pack/license | TBD | TBD | Existing user library; inventory before use |
| KayKit : Medieval Hexagon Pack (1.0), 25-model subset | Kay Lousberg | github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 @ 84fa4e91af6a | CC0 1.0 (LICENSE.txt kept) | No; files flattened beside the shared texture | `assets/third_party/kaykit/medieval_hexagon/` | Village buildings, mills, fields, fences, clouds, props, distant Bellhaven. (Trees and rocks were replaced by Quaternius.) Combat-themed models excluded. |
| KayKit : Furniture Bits (1.0), 15-model subset | Kay Lousberg | github.com/KayKit-Game-Assets/KayKit-Furniture-Bits-1.0 @ 96d5930a8dbd | CC0 1.0 (LICENSE.txt kept) | No | `assets/third_party/kaykit/furniture_bits/` | Cottage and Atrium furniture |
| KayKit : Restaurant Bits (1.0), 7-model subset | Kay Lousberg | github.com/KayKit-Game-Assets/KayKit-Restaurant-Bits-1.0 @ 153c8a7535b4 | CC0 1.0 (LICENSE.txt kept) | No | `assets/third_party/kaykit/restaurant_bits/` | Tableware, produce crates, kitchen bits |
| EB Garamond (variable weight) | The EB Garamond Project Authors | github.com/google/fonts @ 47d54ca1ebb1, ofl/ebgaramond | SIL OFL 1.1 (OFL.txt kept) | Renamed only | `assets/third_party/fonts/eb_garamond/` | Interface serif, matching the concept mockup |
| Bread oven (AI-generated) | Generated with Artlist (Nano Banana 2 concept, Hyper3D Rodin v2.5 Fast 3D) | Artlist, owner's subscription, 2026-10-21 | Artlist terms for AI output; owner approved use 2026-10-21, terms text not retrieved (re-check before commercial release) | Yes: baked to vertex colours, simplified to ~2,500 triangles | `assets/third_party/artlist/` | Domed bread oven outside the bakery |
| Kenney : Impact Sounds (1.0) and Interface Sounds (1.0), 22 sounds | Kenney | kenney.nl/assets/impact-sounds, kenney.nl/assets/interface-sounds | CC0 1.0 (License.txt kept) | Renamed, trimmed, mono, levelled, re-encoded as Ogg Vorbis | `assets/third_party/audio/kenney/` | Wooden taps for placing pieces, footsteps on grass, wood and stone, a soft drop and a confirmation |
| Freesound field recordings, 13 sounds | Tonmeister88, HullMusic, pepasystem, Nox_Sound, CheatinSloth, satoristudios3, michaelperfect, D4XX, craigsmith, SpaceJoe | freesound.org (ids and links in `CREDITS.txt`), via the Freesound API, 2026-10-22 | CC0 1.0, every sound | HQ Ogg previews; levelled, trimmed, loops crossfaded, mono except ambience beds | `assets/third_party/audio/freesound/` | Meadow birds, wood stove, river, waterfall, fountain, sheep, hens, page turns. Every other sound is synthesized in `autoload/audio_service.gd`. |

The per-file, machine-readable record is `assets/third_party/manifest.json`. The content validator fails on any file under `assets/third_party/` that the manifest doesn't list. Scale, pivot and collision normalization is in `assets/props.json`.

## Import Rule
No third-party asset enters a production scene until its manifest entry is complete.
