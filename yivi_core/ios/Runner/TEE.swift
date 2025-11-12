import Foundation

enum TEEError: Error {
    case unsupportedAlgorithm
    case unavailablePublicKey
    case incorrectBlockSize
    case keyGenerationFailed
    case keyNotFound
}
// Trusted Execution Environment (TEE) class
public class TEE : NSObject, IrmagobridgeSignerProtocol {
    final let encryptionAlgorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    
    public func sign(_ keyAlias: String?, msg: Data?) throws -> Data {
        guard let key = tryLoadKey(keyAlias!) else {
            throw TEEError.keyNotFound
        }
        
        var error: Unmanaged<CFError>?
        let signature = SecKeyCreateSignature(key, .ecdsaSignatureMessageX962SHA256, msg! as CFData, &error) as Data?
        guard signature != nil else {
            throw error!.takeRetainedValue() as Error
        }
        return signature!
    }
    
    public func publicKey(_ keyAlias: String?) throws -> Data {
        var privateKey = tryLoadKey(keyAlias!)
        if privateKey == nil {
            privateKey = try generateKey(keyAlias!)
        }
        return try keyToData(SecKeyCopyPublicKey(privateKey!)!)
    }
    
    func encrypt(_ tag: String, _ plaintext: Data) throws -> Data {
        var key = tryLoadKey(tag)
        if key == nil {
            key = try generateKey(tag)
        }
        
        var error: Unmanaged<CFError>?
        
        guard let pk = SecKeyCopyPublicKey(key!) else {
            throw TEEError.unavailablePublicKey
        }
        
        guard SecKeyIsAlgorithmSupported(pk, .encrypt, encryptionAlgorithm) else {
            throw TEEError.unsupportedAlgorithm
        }
        
        guard let ciphertext = SecKeyCreateEncryptedData(pk,
                                                         encryptionAlgorithm,
                                                         plaintext as CFData,
                                                         &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        
        return ciphertext
    }
    
    func decrypt(_ tag: String, _ ciphertext: Data) throws -> Data {
        var error: Unmanaged<CFError>?
        
        let key: SecKey = try getKey(tag)
        
        guard SecKeyIsAlgorithmSupported(key, .decrypt, encryptionAlgorithm) else {
            throw TEEError.unsupportedAlgorithm
        }
        
        guard let plaintext = SecKeyCreateDecryptedData(key,
                                                        encryptionAlgorithm,
                                                        ciphertext as CFData,
                                                        &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        
        return plaintext
    }
    
    private func keyToData(_ pk: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let pkdata = SecKeyCopyExternalRepresentation(pk, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        
        // We want to return a key in PKIX, ASN.1 DER form, but SecKeyCopyExternalRepresentation
        // returns the coordinates X and Y of the public key as follows: 04 || X || Y. We convert
        // that to a valid PKIX key by prepending the SPKI of secp256r1 in DER format.
        // Based on https://stackoverflow.com/a/45188232.
        let secp256r1Header = Data([
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
            0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00
        ])
        return secp256r1Header + pkdata
    }
    
    private func keyExists(_ tag: String) -> Bool {
        return tryLoadKey(tag) != nil
    }
    
    private func tryLoadKey(_ tag: String) -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag.data(using: .utf8)!,
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecReturnRef as String             : true
        ]
        
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)
    }
    
    private func generateKey(_ tag: String) throws -> SecKey {
        var error: Unmanaged<CFError>?
        
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            &error
        ) else {
            throw error!.takeRetainedValue() as Error
        }
        
        var attributes: [String: Any] = [
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecAttrTokenID as String           : kSecAttrTokenIDSecureEnclave,
            kSecAttrKeySizeInBits as String     : 256,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String       : true,
                kSecAttrApplicationTag as String    : tag.data(using: .utf8)!,
                kSecAttrAccessControl as String     : access
            ] as [String : Any]
        ]
        
        // Try to generate key in Secure Enclave. If it succeeds, we return.
        // Otherwise, we continue to look for a fallback.
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            let retainedError = error!.takeRetainedValue() as CFError
            if CFErrorGetCode(retainedError) != errSecUnimplemented {
                throw retainedError
            }
            // Secure Enclave is not available. Falling back to a key stored in the iOS keychain.
            attributes.removeValue(forKey: kSecAttrTokenID as String)
            guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
                throw error!.takeRetainedValue() as CFError
            }
            return key
        }
        
        return key
    }
    
    private func getKey(_ tag: String) throws -> SecKey {
        guard let key = tryLoadKey(tag) else {
            throw TEEError.keyNotFound
        }
        return key
    }
}
