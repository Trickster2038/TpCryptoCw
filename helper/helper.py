import hashlib

"""
this module generates hashes for CRNL contract
"""

print("=== hash generator for CRNL contract ===\n")

print("Enter your N:")
n = int(input())
print("Enter your Salt:")
salt = int(input())

secret = (1<<255) + (n<<128) + salt
# print("Secret num:")
# print(secret)

secret_b = (secret).to_bytes(32, byteorder='big') # 256bits = 32 bytes
# print("Secret bin:")
# print(secret_b)

hash_object = hashlib.sha256(secret_b)
hex_dig = hash_object.hexdigest()

print("\nHash (hex), use as string:") 
print("\"0x" + str(hex_dig) + "\"")

# print("Result dec:") 
# print(int(str(hex_dig), 16))