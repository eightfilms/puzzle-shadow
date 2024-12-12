# puzzle-shadow

This is not my submitted solution (I included only the `Prover.toml` as my [solution](https://gist.github.com/eightfilms/9ff8f540bf44f79f70000117ad54daf2)), but this repo includes fixes suggested in my [writeup](https://gist.github.com/eightfilms/eb544879e47d3b678cbaf766bf94186e). Please take a look at those links for my solution and writeup submissions respectively.

## Setup

### Noir
Install Noir v0.37.0.

```
curl -L noirup.dev | bash
noirup --version 0.37.0
```

### Proving Backend
Install the compatible version of the `bb` CLI for the Barretenberg proving backend.

```
curl -L bbup.dev | bash
bbup --version 0.61.0
```

## Generate the witness & proof

Generate the witness:   
```
nargo execute
```

Generate the proof:
```
bb prove -b ./target/puzzle3.json -w ./target/puzzle3.gz -o ./target/proof
```

Verify the proof:
```
bb verify -p ./target/proof
```

## (For documentation only, no need for the puzzle) - Generate the circuit and vk

Compile:
```
nargo compile
```

Generate the verification key:
```
bb write_vk -b ./target/puzzle3.json -o ./target/vk
```
