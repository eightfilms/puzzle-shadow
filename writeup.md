# ZK Hack V: Shadow

TL:DR - Alice, given her public key and pepper, with knowledge of Bob's public key, can authenticate a transaction using Bob's public key by exploiting 2 important parts of the Noir program that are unconstrained; specifically 1) the length of the message to perform the SHA256 hash on, and 2) the indices between which the public key is searched for in the identifier string.

## Noir and Nargo

### Noir

[Noir](https://noir-lang.org/) is an open-source Domain Specific Language (DSL) created by the team at [Aztec](https://aztec.network/) for the construction of privacy-preserving Zero-Knowledge programs, requiring no previous knowledge on the underlying mathematics or cryptography.

A Noir program is made provable in two steps. Firstly, A Noir program is compiled to an adaptable intermediate language known as ACIR. From there, depending on a given project's needs, ACIR can be further compiled into an arithmetic circuit for integration with the proving backend.

### Nargo

Nargo provides the ability to initiate and execute Noir projects - it is the equivalent of Rust's cargo for Noir. The notes referenced here are a summarized form of this [page](https://noir-lang.org/docs/getting_started/project_breakdown) relevant for understanding the puzzle.

### Project structure

Given a `main.nr`, we have a `main(..)` function which is the entrypoint to our Noir program, and its arguments are inputs to our Noir program. Let's take our puzzle for example:

```nr
fn main(
    identifier: BoundedVec<u8, 128>,
    pub_key: pub [u8; 32],
    whitelist: pub [[u8; 32]; 10]) { ... }
```

Inputs are private by default unless marked with a `pub` keyword before its type.

Our puzzle takes in:
- `identifier`: A [`BoundedVec`](https://noir-lang.org/docs/dev/noir/standard_library/containers/boundedvec) holding a byte array of a maximum of 128 bytes.
- `pub_key`: An array of 32 bytes. This is public.
- `white_list`. An array of 10 whitelisted `pub_key`s, each of which is an array of 32 bytes. This is public.

These inputs are specified within [`Prover.toml`](https://github.com/ZK-Hack/puzzle-shadow/blob/main/Prover.toml) which is provided in the puzzle:

```toml
# BEGIN DON'T CHANGE THIS SECTION

pub_key = [157, 133, 167, 136, 43, 161, 75, 166, 33, 14, 35, 106, 238, 18, 60, 56, 93, 209, 205, 52, 247, 110, 174, 192, 20, 58, 70, 42, 215, 98, 195, 150]
whitelist = [
    [235, 220, 189, 130, 58, 65, 55, 20, 75, 101, 34, 52, 87, 237, 210, 230, 97, 44, 199, 54, 139, 184, 61, 103, 40, 41, 177, 255, 90, 133, 243, 162],
    [104, 166, 62, 181, 1, 228, 244, 115, 180, 141, 231, 245, 235, 232, 254, 20, 44, 223, 11, 8, 122, 250, 202, 224, 78, 198, 165, 211, 249, 86, 201, 161],
    [131, 135, 86, 204, 58, 1, 220, 226, 90, 219, 112, 36, 1, 32, 243, 102, 219, 56, 119, 222, 191, 237, 192, 62, 176, 73, 50, 160, 23, 243, 250, 21],
    [14, 246, 194, 80, 125, 192, 12, 37, 168, 229, 132, 71, 41, 218, 184, 95, 126, 140, 231, 73, 188, 67, 87, 30, 31, 2, 72, 186, 89, 254, 138, 174],
    [197, 93, 46, 57, 214, 23, 120, 199, 214, 34, 1, 202, 41, 227, 230, 122, 177, 5, 179, 4, 197, 95, 230, 61, 152, 120, 106, 49, 96, 175, 169, 154],
    [32, 197, 4, 79, 137, 124, 121, 121, 120, 190, 124, 73, 155, 106, 147, 81, 49, 138, 184, 149, 43, 22, 108, 75, 134, 0, 97, 84, 145, 114, 198, 230],
    [60, 38, 50, 20, 10, 157, 111, 208, 222, 231, 6, 226, 147, 32, 50, 158, 54, 253, 120, 103, 17, 99, 147, 1, 14, 52, 229, 120, 229, 115, 252, 197],
    [185, 43, 209, 227, 198, 215, 98, 164, 22, 119, 133, 252, 151, 141, 83, 27, 200, 38, 148, 139, 71, 213, 35, 250, 108, 23, 172, 249, 62, 248, 222, 152],
    [190, 80, 189, 89, 178, 25, 7, 226, 190, 11, 159, 71, 247, 207, 103, 179, 22, 156, 195, 99, 232, 20, 61, 170, 214, 81, 246, 35, 211, 184, 77, 152],
    [190, 109, 123, 228, 174, 32, 60, 171, 12, 164, 196, 218, 12, 200, 191, 101, 28, 15, 130, 203, 4, 165, 3, 157, 68, 159, 122, 209, 184, 103, 215, 149]
]

# END DON'T CHANGE THIS SECTION

# BEGIN HACK

[identifier]
len = "128"
storage = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# END HACK
```

During `nargo execute`, nargo will execute the Noir program using the inputs specified in `Prover.toml`. Executions fails if either the constraints fail or if a given input is invalid according to its type. This means that the `storage` input of the `identifier` **must** be of length 128. You can easily verify this by deleting one of the 0s and running `nargo execute` (output trimmed for readability):

```console
$ nargo execute
The value passed for parameter `identifier.storage` does not match the specified type:
Type Array { length: 128, typ: Integer { sign: Unsigned, width: 8 } } is expected to have length 128 but value Vec( ... ) has length 127
```

We're skipping a bit ahead here, but we now know the 2 conditions for which we can't successfully execute the program. (This condition will be relevant later...)

### Constraints

In Noir, a constraint is simply an `assert(..)` statement for which the expression within should evaluate to `true`. For example, a Noir program with `assert(1 == 2)` would, for obvious reasons, fail to be solved due to the unsatisfied constraint.

Now that we've covered all the basics, let's try to solve the puzzle!

## Solution

We have established that we can't successfully execute the program on 2 conditions, and we showed 1 of the conditions above. The other condition is if the constraints fail. There are two assertions in our program, which means there are two constraints.

In plain English, the two assertions require us to show:

1. that **Alice** is whitelisted, and
2. that **Alice** can act as **Bob** knowing the above information.

### Showing that Alice is whitelisted

The first part of the puzzle requires us to show that Alice is whitelisted:

```nr
    // the identifier hashes to a digest that is in the public whitelist
    let digest = std::hash::sha256_var(identifier.storage(), identifier.len() as u64);
    let mut present = false;
    for i in 0..whitelist.len() {
        if whitelist[i] == digest {
            present = true;
        }
    }
    assert(present);
```

The key function used here is the [`std::hash::sha256_var`](https://github.com/noir-lang/noir/blob/1b0dd4149d9249f0ea4fb5e2228c688e0135618f/noir_stdlib/src/hash/sha256.nr#L64), which is Noir's SHA256 stdlib implementation. Notably, this is _variable sized_, since it takes the length of the message to hash as a second argument. We are hashing the `identifier` to receive a `digest`, which is checked for existence within the `whitelist`.

We also know from the provided `README.md` that the `identifier` is a string of the form `{pk}_{pepper}`, where `pk` is the public key while `pepper` is a secret value sampled from http://JWT.pk.

In `main.nr`, we are given Alice's public key and pepper in arrays of 32 bytes each:

```nr
// alice_pk = [155, 143, 27, 66, 87, 125, 33, 110, 57, 153, 93, 228, 167, 76, 120, 220, 178, 200, 187, 35, 211, 175, 104, 63, 140, 208, 36, 184, 88, 1, 203, 62]
// alice_pepper = [213, 231, 76, 105, 105, 96, 199, 183, 106, 26, 29, 7, 28, 234, 145, 69, 48, 9, 254, 205, 79, 21, 90, 13, 39, 172, 114, 59, 131, 15, 78, 118]
```

To obtain Alice's `identifier`, we would need to perform a SHA256 hash of the string `{alice_pk}_{alice_pepper}`, which means we need `storage` to represent that identifier. We need to insert an underscore between the two arrays. `_` has the value of **95** according to its [UTF-8 encoding](https://www.charset.org/utf-8). Now if we build the string, we have something like this:

```toml
storage = [
# alice pk start
155, 143, 27, 66, 87, 125, 33, 110, 57, 153, 93, 228, 167, 76, 120, 220, 178, 200, 187, 35, 211, 175, 104, 63, 140, 208, 36, 184, 88, 1, 203, 62,
# alice pk end
# underscore character start
95,
# underscore character end
# alice pepper start
213, 231, 76, 105, 105, 96, 199, 183, 106, 26, 29, 7, 28, 234, 145, 69, 48, 9, 254, 205, 79, 21, 90, 13, 39, 172, 114, 59, 131, 15, 78, 118
# alice pepper end
]
```

Let's try editing `storage` within `Prover.toml` to reflect this.

```toml
[identifier]
len = "128"
storage = [155, 143, 27, 66, 87, 125, 33, 110, 57, 153, 93, 228, 167, 76, 120, 220, 178, 200, 187, 35, 211, 175, 104, 63, 140, 208, 36, 184, 88, 1, 203, 62, 95, 213, 231, 76, 105, 105, 96, 199, 183, 106, 26, 29, 7, 28, 234, 145, 69, 48, 9, 254, 205, 79, 21, 90, 13, 39, 172, 114, 59, 131, 15, 78, 118]
```

We've solved it! Or not...?

```console
$ nargo execute --silence-warnings
The value passed for parameter `identifier.storage` does not match the specified type:
Type Array { length: 128, typ: Integer { sign: Unsigned, width: 8 } } is expected to have length 128 but value Vec([Field(155), Field(143), Field(27), Field(66), Field(87), Field(125), Field(33), Field(110), Field(57), Field(153), Field(93), Field(228), Field(167), Field(76), Field(120), Field(220), Field(178), Field(200), Field(187), Field(35), Field(211), Field(175), Field(104), Field(63), Field(140), Field(208), Field(36), Field(184), Field(88), Field(1), Field(203), Field(62), Field(95), Field(213), Field(231), Field(76), Field(105), Field(105), Field(96), Field(199), Field(183), Field(106), Field(26), Field(29), Field(7), Field(28), Field(234), Field(145), Field(69), Field(48), Field(9), Field(254), Field(205), Field(79), Field(21), Field(90), Field(13), Field(39), Field(172), Field(114), Field(59), Field(131), Field(15), Field(78), Field(118)]) has length 65
```

The output tells us that we've passed in an array of length **65**, when it expected a length of **128** due to the type definition of `BoundedVec`.

The first thought here might be to alter the `len` input as well:

```toml
[identifier]
len = "65"
storage = [155, 143, 27, 66, 87, 125, 33, 110, 57, 153, 93, 228, 167, 76, 120, 220, 178, 200, 187, 35, 211, 175, 104, 63, 140, 208, 36, 184, 88, 1, 203, 62, 95, 213, 231, 76, 105, 105, 96, 199, 183, 106, 26, 29, 7, 28, 234, 145, 69, 48, 9, 254, 205, 79, 21, 90, 13, 39, 172, 114, 59, 131, 15, 78, 118]
```

But you will find that the same error occurs... which is weird - isn't `len` talking about the length of the `BoundedVec`?

To understand what's going on under the hood, let's explore its  [definition](https://github.com/noir-lang/noir/blob/1b0dd4149d9249f0ea4fb5e2228c688e0135618f/noir_stdlib/src/collections/bounded_vec.nr#L25-L28):

```nr
pub struct BoundedVec<T, let MaxLen: u32> {
    storage: [T; MaxLen],
    len: u32,
}
```

`storage` is a backing array, while `len` tells us the current length of the array.

The noir documentation does not have information on how to pass structs into the program, but there is information on how to pass an [array of structs](https://noir-lang.org/docs/getting_started/project_breakdown#arrays-of-structs), and from there you can infer that the way to pass a struct into the program is via a [table](https://toml.io/en/v1.0.0#table) according to the TOML spec. That means that to pass a `BoundedVec` as input, both `storage` and `len` must be present in this form:

```
[identifier]
len = foo 
storage = bar
```

The tricky thing about the definition and the way this works is, `len` is not supposed to be manipulated outside of the `BoundedVec` implementation! From studying the `BoundedVec` source code, you might gather that the `len` value should only be updated upon actions to the backing array, eg. pushing an element or extending from an array.

In our case, since `std::hash::sha256_var` takes in `identifier.len()` as the 2nd argument, we can exploit this knowledge to our advantage by attempting to pass in anything other than the `BoundedVec`'s max size of **128** as the `len` input in `Prover.toml`, along with the original zero vector of length **128**, just to see what happens:

In `Prover.toml`:
```toml
[identifier]
len = "0"
storage = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

If we change `len` to **0**, notice that the program is still ran with constraints failing:

```console
$ nargo execute --silence-warnings
error: Failed constraint
   ┌─ /Users/eightfilms/noir/puzzle-shadow/src/main.nr:17:12
   │
17 │     assert(present);
   │            -------
   │
   = Call stack:
     1. /Users/eightfilms/noir/puzzle-shadow/src/main.nr:17:12

Failed to solve program: 'Cannot satisfy constraint'
```

That means that our hash function still ran on our input, which means we can technically pass any `u32` value as our `len`, even if it's not an accurate representation of the current size of our backing array.

More importantly, this also implies we can pad `storage` (which acts as our backing array) with 0s to the declared length of **128** to satisfy the type checking, while declaring `len` as **65**!

Let's see it in action:

```toml
[identifier]
len = "65"
storage = [155, 143, 27, 66, 87, 125, 33, 110, 57, 153, 93, 228, 167, 76, 120, 220, 178, 200, 187, 35, 211, 175, 104, 63, 140, 208, 36, 184, 88, 1, 203, 62, 95, 213, 231, 76, 105, 105, 96, 199, 183, 106, 26, 29, 7, 28, 234, 145, 69, 48, 9, 254, 205, 79, 21, 90, 13, 39, 172, 114, 59, 131, 15, 78, 118, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

```console
$ nargo execute --silence-warnings
error: Assertion failed: 'utils::search could not find needle in haystack'
   ┌─ /Users/eightfilms/nargo/github.com/noir-lang/noir_string_search.gitv0.3.0/src/utils.nr:27:12
   │
27 │     assert(found == true, "utils::search could not find needle in haystack");
   │            -------------
   │
   = Call stack:
     1. /Users/eightfilms/noir/puzzle-shadow/src/main.nr:22:36
     2. /Users/eightfilms/nargo/github.com/noir-lang/noir_string_search.gitv0.3.0/src/lib.nr:238:13
     3. /Users/eightfilms/nargo/github.com/noir-lang/noir_string_search.gitv0.3.0/src/utils.nr:27:12

Failed assertion
```

We've reached the second assertion, which means we've passed the first assertion!

### Showing that **Alice** can act as **Bob**

Now we need to show that **Alice** can act as **Bob**, given her own public key, pepper, and knowledge of Bob's public key.

The second assertion is a slightly simpler affair. It asserts that Bob's public key is found within the `identifier` as a substring using a [string search library](https://github.com/noir-lang/noir_string_search).

We know from above that we can manipulate the hash function to only use the first **65** elements of the backing array, which means anything after that is padding. We can simply embed Bob's public key after Alice's identifier string, replacing a part of the padding:

```toml
[identifier]
len = "65"
storage = [155, 143, 27, 66, 87, 125, 33, 110, 57, 153, 93, 228, 167, 76, 120, 220, 178, 200, 187, 35, 211, 175, 104, 63, 140, 208, 36, 184, 88, 1, 203, 62, 95, 213, 231, 76, 105, 105, 96, 199, 183, 106, 26, 29, 7, 28, 234, 145, 69, 48, 9, 254, 205, 79, 21, 90, 13, 39, 172, 114, 59, 131, 15, 78, 118, 
# bob's public key start
157, 133, 167, 136, 43, 161, 75, 166, 33, 14, 35, 106, 238, 18, 60, 56, 93, 209, 205, 52, 247, 110, 174, 192, 20, 58, 70, 42, 215, 98, 195, 150,
# bob's public key end
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

```console
$ nargo execute --silence-warnings
[puzzle3] Circuit witness successfully solved
[puzzle3] Witness saved to /Users/eightfilms/noir/puzzle-shadow/target/puzzle3.gz
```

Huzzah! We've solved the puzzle - Alice has successfully shadowed Bob to steal his funds!

### (Bonus) Fixing this vulnerability

How might we fix this program to disallow Alice from stealing funds?

#### Use an `Array` instead of `BoundedVec`

There is no reason to use a `BoundedVec` to represent the `identifier`, since we know that the `identifier` is always of the form `{pk}_{pepper}`, which is of length **65**. This means that the `identifier` will not grow or shrink in length during the runtime of the program. Instead, let's just use an [array](https://noir-lang.org/docs/dev/noir/concepts/data_types/arrays) of length **65**:

```nr
fn main(identifier: [u8; 65], pub_key: pub [u8; 32], whitelist: pub [[u8; 32]; 10]) { ... }
```

Our hash will now always only hash a message of a constant length of **65**:

```nr
    let digest = std::hash::sha256_var(identifier, identifier.len() as u64);
```

This change is already enough to prevent the exploit, but let's also fix the second part of the puzzle.

#### Limiting the search range of `substring_match`, or even replacing it

The string search library instantiates a `StringBody` of length **128**, which is the length of the string to search within. We can simply change this to **32**, since this is the length of the public key itself. This essentially means we're just doing a string equality check.

A better fix, since we know exactly where the `pub_key` lives, would just be to compare the bytes directly with a [for loop](https://noir-lang.org/docs/noir/concepts/control_flow/#loops)!

Not only is this a cleaner solution, but we also get rid of an unnecessary dependency, which can be a source of bugs (eg. supply chain attacks).

With the above fix, `main.nr` will look like this:

```nr
// THIS FILE CANNOT BE CHANGED

// alice_pk = [155, 143, 27, 66, 87, 125, 33, 110, 57, 153, 93, 228, 167, 76, 120, 220, 178, 200, 187, 35, 211, 175, 104, 63, 140, 208, 36, 184, 88, 1, 203, 62]
// alice_pepper = [213, 231, 76, 105, 105, 96, 199, 183, 106, 26, 29, 7, 28, 234, 145, 69, 48, 9, 254, 205, 79, 21, 90, 13, 39, 172, 114, 59, 131, 15, 78, 118]

fn main(identifier: [u8; 65], pub_key: pub [u8; 32], whitelist: pub [[u8; 32]; 10]) {
    // the identifier hashes to a digest that is in the public whitelist
    let digest = std::hash::sha256_var(identifier, identifier.len() as u64);
    let mut present = false;
    for i in 0..whitelist.len() {
        if whitelist[i] == digest {
            present = true;
        }
    }
    assert(present);

    // the specified public key is in the identifier's first 32 bytes
    for i in 0..32 {
        assert(identifier[i] == pub_key[i]);
    }
}
```

I've included this fixed version in this [repo](https://github.com/eightfilms/puzzle-shadow).

Thank you if you've read all the way here to the end!
