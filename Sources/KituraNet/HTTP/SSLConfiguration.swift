/*
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import NIOOpenSSL
import SSLService
import LoggerAPI

/// A helper class to bridge betweem SSLService.Configuration (used by Kitura) and TLSConfiguration required by NIOOpenSSL
internal class SSLConfiguration {
   
    private var certificateFilePath: String?
    
    private var keyFilePath: String?

    private var certificateChainFilePath: String?

    private var password: String?
    
    // TODO: Consider other TLSConfiguration options (cipherSuites, trustRoots, applicationProtocols, etc..)

    /// Initialize using SSLService.Configuration
    init(sslConfig: SSLService.Configuration) {
        self.certificateFilePath = sslConfig.certificateFilePath
        self.keyFilePath = sslConfig.keyFilePath
        self.certificateChainFilePath = sslConfig.certificateChainFilePath
        self.password = sslConfig.password
    }

    /// Convert SSLService.Configuration to NIOOpenSSL.TLSConfiguration
    func tlsServerConfig() -> TLSConfiguration? {
            // TODO: Consider other configuration options
            if let certificateFilePath = certificateFilePath, let keyFilePath = keyFilePath {
                return TLSConfiguration.forServer(certificateChain: [.file(certificateFilePath)], privateKey: .file(keyFilePath))
            } else {
                /// TLSConfiguration for PKCS#12 formatted certificate
                guard let certificateChainFilePath = certificateChainFilePath, let password = password else { return nil }
                do {
                    let pkcs12Bundle = try OpenSSLPKCS12Bundle(file: certificateChainFilePath, passphrase: password.utf8)
                    var sslCertificateSource: [OpenSSLCertificateSource] = []
                    pkcs12Bundle.certificateChain.forEach {
                        sslCertificateSource.append(.certificate($0))
                    }
                    return TLSConfiguration.forServer(certificateChain: sslCertificateSource, privateKey: .privateKey(pkcs12Bundle.privateKey))
                } catch let error {
                    Log.error("Error creating the TLS server configuration: \(error)")
                    return nil
                }
            }
    }
}
