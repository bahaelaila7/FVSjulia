# base/uuidgen.jl — UUIDGEN: generate a UUID v4 string
# Translated from: bin/FVSsn_buildDir/uuidgen.f (110 lines)
#
# Returns a 36-char lowercase UUID v4 string:
#   xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
# where y ∈ {8,9,a,b}.
# Julia's built-in `rand()` replaces the Fortran random_number() calls.

function UUIDGEN()::String
    bytes = rand(UInt8, 16)   # 16 random bytes = 128 bits

    # Set version 4 bits (bits 12-15 of byte 7 = 0100)
    bytes[7] = (bytes[7] & UInt8(0x0f)) | UInt8(0x40)

    # Set variant bits (bits 6-7 of byte 9 = 10xx)
    bytes[9] = (bytes[9] & UInt8(0x3f)) | UInt8(0x80)

    return @sprintf(
        "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        bytes[1],  bytes[2],  bytes[3],  bytes[4],
        bytes[5],  bytes[6],
        bytes[7],  bytes[8],
        bytes[9],  bytes[10],
        bytes[11], bytes[12], bytes[13], bytes[14], bytes[15], bytes[16]
    )
end
