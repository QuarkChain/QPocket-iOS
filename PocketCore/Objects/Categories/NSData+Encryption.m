//
//  NSData+Encryption.m
//  Breadcrumb
//
//  Created by Andrew Hurst on 2/6/15.
//  Copyright (c) 2015 Breadcrumb.
//
//  Distributed under the MIT software license, see the accompanying
//  file LICENSE or http://www.opensource.org/licenses/mit-license.php.
//
//

#import "NSData+Encryption.h"
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonCryptor.h>

CFAllocatorRef SecureAllocator(void);

static void *secureAllocate(CFIndex allocSize, CFOptionFlags hint, void *info) {
    void *ptr = CC_XMALLOC(sizeof(CFIndex) + (unsigned long)allocSize);
    
    if (ptr) {  // we need to keep track of the size of the allocation so it can
        // be cleansed before deallocation
        *(CFIndex *)ptr = allocSize;
        return (CFIndex *)ptr + 1;
    } else
        return NULL;
}

static void secureDeallocate(void *ptr, void *info) {
    CFIndex size = *((CFIndex *)ptr - 1);
    
    if (size) {
        CC_XZEROMEM(ptr, (unsigned long)size);
        CC_XFREE((CFIndex *)ptr - 1, sizeof(CFIndex) + size);
    }
}

static void *secureReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint,
                              void *info) {
    // There's no way to tell ahead of time if the original memory will be
    // deallocted even if the new size is smaller
    // than the old size, so just cleanse and deallocate every time.
    void *newptr = secureAllocate(newsize, hint, info);
    CFIndex size = *((CFIndex *)ptr - 1);
    
    if (newptr && size) {
        CC_XMEMCPY(newptr, ptr, (size < newsize) ? (unsigned long)size : (unsigned long)newsize);
        secureDeallocate(ptr, info);
    }
    
    return newptr;
}

// Since iOS does not page memory to storage, all we need to do is cleanse
// allocated memory prior to deallocation.
inline CFAllocatorRef SecureAllocator() {
    static CFAllocatorRef alloc = NULL;
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        CFAllocatorContext context;
        
        context.version = 0;
        CFAllocatorGetContext(kCFAllocatorDefault, &context);
        context.allocate = secureAllocate;
        context.reallocate = secureReallocate;
        context.deallocate = secureDeallocate;
        
        alloc = CFAllocatorCreate(kCFAllocatorDefault, &context);
    });
    
    return alloc;
}

@implementation NSMutableData (Bitcoin)

+ (NSMutableData *)secureDataWithCapacity:(NSUInteger)aNumItems {
    return CFBridgingRelease(CFDataCreateMutable(SecureAllocator(), (CFIndex)aNumItems));
}

+ (NSMutableData *)secureDataWithLength:(NSUInteger)length {
    NSMutableData *d = [self secureDataWithCapacity:length];
    
    d.length = length;
    return d;
}

+ (NSMutableData *)secureDataWithData:(NSData *)data {
    return CFBridgingRelease(
                             CFDataCreateMutableCopy(SecureAllocator(), 0, (__bridge CFDataRef)data));
}

@end

@implementation NSData (Hash)

- (NSData *)SHA1 {
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(self.bytes, (CC_LONG)self.length, d.mutableBytes);
    
    return d;
}

- (NSData *)SHA256 {
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(self.bytes, (CC_LONG)self.length, d.mutableBytes);
    
    return d;
}

- (NSData *)SHA256_2 {
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(self.bytes, (CC_LONG)self.length, d.mutableBytes);
    CC_SHA256(d.bytes, (CC_LONG)d.length, d.mutableBytes);
    
    return d;
}

- (NSData *)SHA512 {
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
    
    CC_SHA512(self.bytes, (CC_LONG)self.length, d.mutableBytes);
    
    return d;
}

- (NSData *)SHA512HmacWithKey:(NSData *)key {
    NSMutableData *d;
    NSParameterAssert([key isKindOfClass:[NSData class]]);
    if (![key isKindOfClass:[NSData class]]) return NULL;
    
    d = [NSMutableData dataWithLength:CC_SHA512_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA512, key.bytes, key.length, self.bytes,
           (CC_LONG)self.length, d.mutableBytes);
    
    return [d isKindOfClass:[NSData class]] ? d : NULL;
}

//- (NSData *)RMD160 {
//    NSMutableData *d = [NSMutableData dataWithLength:RIPEMD160_DIGEST_SIZE];
//    ripemd160(self.bytes, self.length, d.mutableBytes);
//    return d;
//}

//- (NSData *)hash160 {
//    return self.SHA256.RMD160;
//}

- (NSData *)reverse {
    NSUInteger l = self.length;
    NSMutableData *d = [NSMutableData dataWithLength:l];
    uint8_t *b1 = d.mutableBytes;
    const uint8_t *b2 = self.bytes;
    
    for (NSUInteger i = 0; i < l; i++) {
        b1[i] = b2[l - i - 1];
    }
    
    return d;
}

@end

// bitwise left rotation, this will typically be compiled into a single
// instruction
#define rotl(a, b) (((a) << (b)) | ((a) >> (32 - (b))))

// salsa20/8 stream cypher: http://cr.yp.to/snuffle.html
static void salsa20_8(uint32_t b[16]) {
  uint32_t x00 = b[0], x01 = b[1], x02 = b[2], x03 = b[3], x04 = b[4],
           x05 = b[5], x06 = b[6], x07 = b[7], x08 = b[8], x09 = b[9],
           x10 = b[10], x11 = b[11], x12 = b[12], x13 = b[13], x14 = b[14],
           x15 = b[15];

  for (int i = 0; i < 8; i += 2) {
    // operate on columns
      (void)(x04 ^= rotl(x00 + x12, 7)), (void)(x08 ^= rotl(x04 + x00, 9)),
      (void)(x12 ^= rotl(x08 + x04, 13)), x00 ^= rotl(x12 + x08, 18);
      (void)(x09 ^= rotl(x05 + x01, 7)), (void)(x13 ^= rotl(x09 + x05, 9)),
      (void)(x01 ^= rotl(x13 + x09, 13)), x05 ^= rotl(x01 + x13, 18);
      (void)(x14 ^= rotl(x10 + x06, 7)), (void)(x02 ^= rotl(x14 + x10, 9)),
      (void)(x06 ^= rotl(x02 + x14, 13)), x10 ^= rotl(x06 + x02, 18);
      (void)(x03 ^= rotl(x15 + x11, 7)), (void)(x07 ^= rotl(x03 + x15, 9)),
      (void)(x11 ^= rotl(x07 + x03, 13)), x15 ^= rotl(x11 + x07, 18);

    // operate on rows
      (void)(x01 ^= rotl(x00 + x03, 7)), (void)(x02 ^= rotl(x01 + x00, 9)),
      (void)(x03 ^= rotl(x02 + x01, 13)), x00 ^= rotl(x03 + x02, 18);
      (void)(x06 ^= rotl(x05 + x04, 7)), (void)(x07 ^= rotl(x06 + x05, 9)),
      (void)(x04 ^= rotl(x07 + x06, 13)), x05 ^= rotl(x04 + x07, 18);
      (void)(x11 ^= rotl(x10 + x09, 7)), (void)(x08 ^= rotl(x11 + x10, 9)),
      (void)(x09 ^= rotl(x08 + x11, 13)), x10 ^= rotl(x09 + x08, 18);
      (void)(x12 ^= rotl(x15 + x14, 7)), (void)(x13 ^= rotl(x12 + x15, 9)),
      (void)(x14 ^= rotl(x13 + x12, 13)), x15 ^= rotl(x14 + x13, 18);
  }

    (void)(b[0] += x00), (void)(b[1] += x01), (void)(b[2] += x02), (void)(b[3] += x03), (void)(b[4] += x04), (void)(b[5] += x05),
    (void)(b[6] += x06), b[7] += x07;
    (void)(b[8] += x08), (void)(b[9] += x09), (void)(b[10] += x10), (void)(b[11] += x11), (void)(b[12] += x12),
    (void)(b[13] += x13), (void)(b[14] += x14), b[15] += x15;
}

static void blockmix_salsa8(uint64_t *dest, const uint64_t *src, uint64_t *b,
                            uint32_t r) {
  CC_XMEMCPY(b, &src[(2 * r - 1) * 8], 64);

  for (uint32_t i = 0; i < 2 * r; i += 2) {
    for (uint32_t j = 0; j < 8; j++) b[j] ^= src[i * 8 + j];
    salsa20_8((uint32_t *)b);
    CC_XMEMCPY(&dest[i * 4], b, 64);
    for (uint32_t j = 0; j < 8; j++) b[j] ^= src[i * 8 + 8 + j];
    salsa20_8((uint32_t *)b);
    CC_XMEMCPY(&dest[i * 4 + r * 8], b, 64);
  }
}

// scrypt key derivation: http://www.tarsnap.com/scrypt.html
static NSData *scrypt(NSData *password, NSData *salt, uint64_t n, uint32_t r,
                      uint32_t p, NSUInteger length) {
  NSMutableData *d = [NSMutableData secureDataWithLength:length];
  uint8_t b[128 * r * p];
  uint64_t x[16 * r], y[16 * r], z[8], *v = CC_XMALLOC(128 * r * (unsigned int)n), m;

  CCKeyDerivationPBKDF(kCCPBKDF2, password.bytes, password.length, salt.bytes,
                       salt.length, kCCPRFHmacAlgSHA256, 1, b, sizeof(b));

  for (uint32_t i = 0; i < p; i++) {
    for (uint32_t j = 0; j < 32 * r; j++) {
      ((uint32_t *)x)[j] =
          CFSwapInt32LittleToHost(*(uint32_t *)&b[i * 128 * r + j * 4]);
    }

    for (uint64_t j = 0; j < n; j += 2) {
      CC_XMEMCPY(&v[j * (16 * r)], x, 128 * r);
      blockmix_salsa8(y, x, z, r);
      CC_XMEMCPY(&v[(j + 1) * (16 * r)], y, 128 * r);
      blockmix_salsa8(x, y, z, r);
    }

    for (uint64_t j = 0; j < n; j += 2) {
      m = CFSwapInt64LittleToHost(x[(2 * r - 1) * 8]) & (n - 1);
      for (uint32_t k = 0; k < 16 * r; k++) x[k] ^= v[m * (16 * r) + k];
      blockmix_salsa8(y, x, z, r);
      m = CFSwapInt64LittleToHost(y[(2 * r - 1) * 8]) & (n - 1);
      for (uint32_t k = 0; k < 16 * r; k++) y[k] ^= v[m * (16 * r) + k];
      blockmix_salsa8(x, y, z, r);
    }

    for (uint32_t j = 0; j < 32 * r; j++) {
      *(uint32_t *)&b[i * 128 * r + j * 4] =
          CFSwapInt32HostToLittle(((uint32_t *)x)[j]);
    }
  }

  CCKeyDerivationPBKDF(kCCPBKDF2, password.bytes, password.length, b, sizeof(b),
                       kCCPRFHmacAlgSHA256, 1, d.mutableBytes, d.length);

  CC_XZEROMEM(b, sizeof(b));
  CC_XZEROMEM(x, sizeof(x));
  CC_XZEROMEM(y, sizeof(y));
  CC_XZEROMEM(z, sizeof(z));
  CC_XZEROMEM(v, 128 * r * (unsigned int)n);
  CC_XFREE(v, 128 * r * (int)n);
  CC_XZEROMEM(&m, sizeof(m));
  return d;
}

@implementation NSData (Encryption)

- (NSData *)AES256ETMEncrypt:(NSData *)key {
  @autoreleasepool {
    NSData *hmac, *iv;
    NSMutableData *enc;
    // Encrypt
    enc = [NSMutableData secureDataWithData:[self AES256Encrypt:key]];
    if (![enc isKindOfClass:[NSData class]]) {
      key = NULL;
      return NULL;
    }

    // Get Hmac IV from key
    iv = [key SHA256];
    key = NULL;
    if (![iv isKindOfClass:[NSData class]]) {
      iv = NULL;
      return NULL;
    }

    // HMAC
    hmac = [enc SHA512HmacWithKey:iv];
    iv = NULL;
    if (![hmac isKindOfClass:[NSData class]]) {
      return NULL;
    }

    // Append fist 8 of hmac
    [enc appendBytes:hmac.bytes length:8];
    return enc;
  }
}

- (NSData *)AES256ETMDecrypt:(NSData *)key {
  @autoreleasepool {
    NSData *check, *iv, *hmac, *enc;
    if (self.length <= 8) {
      key = NULL;
      return NULL;
    }

    // Remove Check (Last 8 bytes)
    check = [self subdataWithRange:NSMakeRange(self.length - 8, 8)];

    // Hmac Verify
    iv = [key SHA256];
    if (![iv isKindOfClass:[NSData class]]) {
      key = NULL;
      return NULL;
    }

    enc = [self subdataWithRange:NSMakeRange(0, self.length - 8)];
    hmac = [enc SHA512HmacWithKey:iv];
    iv = NULL;

    if (![hmac isKindOfClass:[NSData class]]) {
      key = NULL;
      return NULL;
    }

    hmac = [hmac subdataWithRange:NSMakeRange(0, 8)];
    if (![check isEqualToData:hmac]) {
      key = NULL;
      return NULL;
    }
    check = NULL;
    hmac = NULL;

    // Decrypt
    return [enc AES256Decrypt:key];
  }
}

- (NSData *)AES256Encrypt:(NSData *)key {
  return [self AES256CryptOperation:kCCEncrypt withKey:key];
}

- (NSData *)AES256Decrypt:(NSData *)key {
  return [self AES256CryptOperation:kCCDecrypt withKey:key];
}

- (NSData *)AES256CryptOperation:(CCOperation)operation withKey:(NSData *)key {
  @autoreleasepool {
    NSMutableData *secureData =
        [NSMutableData secureDataWithLength:[self length] + kCCBlockSizeAES128];
    NSData *keyData =
        [NSData dataWithBytes:key.bytes length:kCCKeySizeAES256 + 1];

    size_t numBytes = 0;
    CCCryptorStatus cryptStatus = CCCrypt(
        operation, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keyData.bytes,
        kCCKeySizeAES256, NULL /* initialization vector (optional) */,
        self.bytes, self.length,                      /* input */
        [secureData mutableBytes], secureData.length, /* output */
        &numBytes);

    if (cryptStatus == kCCSuccess) {
      secureData.length = numBytes;
      return secureData;
    }

    secureData = NULL;
    return nil;
  }
}

#pragma mark Scrypt

+ (NSData *)scryptPassword:(NSData *)password
                 usingSalt:(NSData *)salt
          withOutputLength:(NSUInteger)length {
  @autoreleasepool {
    return [self scryptPassword:password
                      usingSalt:salt
                     workFactor:16448
                      blockSize:8
          parallelizationFactor:8
               withOutputLength:length];
  }
}

+ (NSData *)scryptPassword:(NSData *)password
                 usingSalt:(NSData *)salt
                workFactor:(uint64_t)n
                 blockSize:(uint32_t)r
     parallelizationFactor:(uint32_t)p
          withOutputLength:(NSUInteger)length {
  @autoreleasepool {
    NSParameterAssert(password);
    if (![password isKindOfClass:[NSData class]]) return NULL;
    return scrypt(password, salt, n, r, p, length);
  }
}

#pragma mark Random

//+ (NSData *)pseudoRandomDataWithLength:(NSUInteger)length {
//  @autoreleasepool {
//    NSMutableData *entropy = [NSMutableData secureDataWithLength:length];
//    int ret = SecRandomCopyBytes(kSecRandomDefault, entropy.length, entropy.mutableBytes);
//    return [entropy isKindOfClass:[NSData class]] ? entropy : NULL;
//  }
//}

@end
