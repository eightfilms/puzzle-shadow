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

    for i in 0..32 {
        assert(identifier[i] == pub_key[i]);
    }
}
