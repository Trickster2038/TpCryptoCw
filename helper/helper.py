import hashlib

#k = keccak.new(digest_bits=256)
print("Enter your N:")
n = int(input())
print("Enter your Salt:")
salt = int(input())

secret = (1<<255) + (n<<128) + salt
print("Secret num:")
print(secret)
#k.update(str((n<<128) + salt).encode())
# k.update((n<<128) + salt)
#result = Integer.parseInt(k.hexdigest(), 16 );

#print(k.hexdigest())
# print(k)
secret_b = (secret).to_bytes(32, byteorder='big') # 256bits = 32 bytes
print("Secret bin:")
print(secret_b)

hash_object = hashlib.sha256(secret_b)
hex_dig = hash_object.hexdigest()

print("Result hex:") 
print(hex_dig)

print("Result dec:") 
print(int(str(hex_dig), 16))