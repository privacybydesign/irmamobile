import Foundation

enum TEEError: Error {
    case unsupportedAlgorithm
    case unavailablePublicKey
    case incorrectBlockSize
    case keyGenerationFailed
    case keyNotFound
}
// Trusted Execution Environment (TEE) class
public class TEE {
    final let encryptionAlgorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    
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
        
        let attributes: [String: Any] = [
                    kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
                    kSecAttrTokenID as String           : kSecAttrTokenIDSecureEnclave,
                    kSecAttrKeySizeInBits as String     : 256,
                    kSecPrivateKeyAttrs as String : [
                        kSecAttrIsPermanent as String       : true,
                        kSecAttrApplicationTag as String    : tag.data(using: .utf8)!,
                        kSecAttrAccessControl as String     : access
                    ]
                ]

        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
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
