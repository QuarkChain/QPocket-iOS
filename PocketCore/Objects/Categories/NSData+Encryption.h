//
//  NSData+Encryption.h
//  Breadcrumb
//
//  Created by Andrew Hurst on 2/6/15.
//  Copyright (c) 2015 Breadcrumb.
//
//  Distributed under the MIT software license, see the accompanying
//  file LICENSE or http://www.opensource.org/licenses/mit-license.php.
//
//

#import <Foundation/Foundation.h>

#ifdef KERNEL
#define    CC_XMALLOC(s)  OSMalloc((s), CC_OSMallocTag)
#define    CC_XFREE(p, s) OSFree((p), (s), CC_OSMallocTag)
#else /* KERNEL */
#include <stdlib.h>
#include <string.h>

#define CC_XMALLOC(s)  malloc(s)
#define CC_XCALLOC(c, s) calloc((c), (s))
#define CC_XREALLOC(p, s) realloc((p), (s))
#define CC_XFREE(p, s)    free(p)
#define CC_XMEMCPY(s1, s2, n) memcpy((s1), (s2), (n))
#define CC_XMEMCMP(s1, s2, n) memcmp((s1), (s2), (n))
#define CC_XMEMSET(s1, s2, n) memset((s1), (s2), (n))
#define CC_XZEROMEM(p, n)    memset((p), 0, (n))
#define CC_XSTRCMP(s1, s2) strcmp((s1), (s2))
#define CC_XSTORE32H(x, y) do {                        \
(y)[0] = (unsigned char)(((x)>>24)&255);            \
(y)[1] = (unsigned char)(((x)>>16)&255);            \
(y)[2] = (unsigned char)(((x)>>8)&255);                \
(y)[3] = (unsigned char)((x)&255);                \
} while(0)
#define CC_XSTORE64H(x, y)                                                                     \
{ (y)[0] = (unsigned char)(((x)>>56)&255); (y)[1] = (unsigned char)(((x)>>48)&255);     \
(y)[2] = (unsigned char)(((x)>>40)&255); (y)[3] = (unsigned char)(((x)>>32)&255);     \
(y)[4] = (unsigned char)(((x)>>24)&255); (y)[5] = (unsigned char)(((x)>>16)&255);     \
(y)[6] = (unsigned char)(((x)>>8)&255); (y)[7] = (unsigned char)((x)&255); }

#define CC_XQSORT(base, nelement, width, comparfunc) qsort((base), (nelement), (width), (comparfunc))

#define CC_XALIGNED(PTR,NBYTE) (!(((size_t)(PTR))%(NBYTE)))

#define CC_XMIN(X,Y) (((X) < (Y)) ? (X): (Y))
#endif

@interface NSData (Encryption)

#pragma mark AES
/*!
 @brief Encrypts the data with AES 256 using the inputted key.

 @param key The key to encrypt the data with.
 */
- (NSData *)AES256Encrypt:(NSData *)key;

/*!
 @brief Decrypts the data with AES 256 using the inputted key.

 @param key The key to decrypt the data with.
 */
- (NSData *)AES256Decrypt:(NSData *)key;

- (NSData *)AES256ETMEncrypt:(NSData *)key;
- (NSData *)AES256ETMDecrypt:(NSData *)key;

#pragma mark Scrypt
/*!
 @brief Scrypts the inputed password with the salt, and the output length.

 @param password The password to to derive from.
 @param salt     The salt to use.
 @param length   The output length.
 */
+ (NSData *)scryptPassword:(NSData *)password
                 usingSalt:(NSData *)salt
          withOutputLength:(NSUInteger)length;

/*!
 @brief Scrypts the inputed password with the inputted algorithm parameters.

 @param password The password to to derive from.
 @param salt     The salt to use.
 @param n        The work factor of the algorithm.
 @param r        The block size of the algorithm.
 @param p        The paralyzation factor of the algorithm.
 @param length   The byte length of the output.
 */
+ (NSData *)scryptPassword:(NSData *)password
                 usingSalt:(NSData *)salt
                workFactor:(uint64_t)n
                 blockSize:(uint32_t)r
     parallelizationFactor:(uint32_t)p
          withOutputLength:(NSUInteger)length;

#pragma mark Sec Random

//+ (NSData *)pseudoRandomDataWithLength:(NSUInteger)length;

- (NSData *)SHA512;

@end
