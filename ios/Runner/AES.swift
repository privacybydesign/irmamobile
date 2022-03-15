import Foundation

enum AESError: Error {
    case unsupportedAlgorithm
    case unavailablePublicKey
    case incorrectBlockSize
    case keyGenerationFailed
    case keyNotFound
}
public class AES {
    final let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
    final let tag: Data = "storageKey".data(using: .utf8)!
    var key: SecKey?
    
    init() throws {
        if (!keyExists()) {
            try generateKey()
        }
        
        key = try getKey()
    }

    func encrypt(_ plaintext: Data) throws -> Data {
        var error: Unmanaged<CFError>?
        let key: SecKey = try getKey()
        
        guard let pk = SecKeyCopyPublicKey(key) else {
            throw AESError.unavailablePublicKey
        }

        guard SecKeyIsAlgorithmSupported(pk, .encrypt, algorithm) else {
              throw AESError.unsupportedAlgorithm
        }

        guard let ciphertext = SecKeyCreateEncryptedData(pk,
                                                         algorithm,
                                                         plaintext as CFData,
                                                         &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        
        return ciphertext
    }
    
    func decrypt(_ ciphertext: Data) throws -> Data {
        var error: Unmanaged<CFError>?

        let key: SecKey = try getKey()

        guard SecKeyIsAlgorithmSupported(key, .decrypt, algorithm) else {
            throw AESError.unsupportedAlgorithm
        }

        guard let plaintext = SecKeyCreateDecryptedData(key,
                                                        algorithm,
                                                        ciphertext as CFData,
                                                        &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        
        return plaintext
    }
    
    private func keyExists() -> Bool {
        return tryLoadKey() != nil
    }
    
    private func tryLoadKey() -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecReturnRef as String             : true
        ]
        
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)
    }
    
    private func generateKey() throws {
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
                        kSecAttrApplicationTag as String    : tag,
                        kSecAttrAccessControl as String     : access
                    ]
                ]

        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            throw error!.takeRetainedValue() as Error
        }
    }
    
    private func getKey() throws -> SecKey {
        guard let key = tryLoadKey() else {
            throw AESError.keyNotFound
        }
        return key
    }
}
