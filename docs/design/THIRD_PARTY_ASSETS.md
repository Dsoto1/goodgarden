# Third-Party Asset Manifest

Track every external asset used in production. Do not assume an entire website has one license; record the exact pack/model and license at time of acquisition.

| Asset / Pack | Creator | Source | License | Modified? | Project Path | Notes |
|---|---|---|---|---|---|---|
| TBD Quaternius packs | Quaternius | TBD | Verify exact pack/license | TBD | TBD | Existing user library; inventory before use |
| KayKit : Medieval Hexagon Pack (1.0), 34-model subset | Kay Lousberg | github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0 @ 84fa4e91af6a | CC0 1.0 (LICENSE.txt kept) | No; files flattened beside the shared texture | `assets/third_party/kaykit/medieval_hexagon/` | Trees, rocks, village buildings, mills, fences, props, distant Bellhaven. Combat-themed models excluded. |
| KayKit : Furniture Bits (1.0), 15-model subset | Kay Lousberg | github.com/KayKit-Game-Assets/KayKit-Furniture-Bits-1.0 @ 96d5930a8dbd | CC0 1.0 (LICENSE.txt kept) | No | `assets/third_party/kaykit/furniture_bits/` | Cottage and Atrium furniture |
| KayKit : Restaurant Bits (1.0), 7-model subset | Kay Lousberg | github.com/KayKit-Game-Assets/KayKit-Restaurant-Bits-1.0 @ 153c8a7535b4 | CC0 1.0 (LICENSE.txt kept) | No | `assets/third_party/kaykit/restaurant_bits/` | Tableware, produce crates, kitchen bits |
| TBD Kenney packs | Kenney | TBD | Verify exact pack/license | TBD | TBD | Candidate props/UI/audio |

The per-file, machine-readable record is `assets/third_party/manifest.json`. The content validator fails on any file under `assets/third_party/` that the manifest doesn't list. Scale, pivot and collision normalization is in `assets/props.json`.

## Import Rule
No third-party asset enters a production scene until its manifest entry is complete.
