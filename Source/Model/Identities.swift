//
//  KnownIdentities.swift
//  FBTT
//
//  Created by Christoph on 5/14/19.
//  Copyright © 2019 Verse Communications Inc. All rights reserved.
//

import Foundation

typealias Identities = [Identity]

struct SSBIdentities {
    let pubs = [ "planetary-pub1": "@cgZaEEyNixAnq7tMH2CHdusBHV80OwqOSGIcc6Hr6aA=.ed25519",
//                "planetary-pub2": "@ZOSbNTyKgIecMcSCPlOJt1veIAP1D8p5Ptao+8cRO6c=.ed25519",
                "planetary-pub3": "@oRMrLWs3AP0VwVw3AtBRL3TfOaxeTOFml33CibRtfcE=.ed25519",
                "cryptix-pub": "@xxZeuBUKIXYZZ7y+CIHUuy0NOFXz2MhUBkHemr86S3M=.ed25519"]

    let people = ["Current Events": "@wNmXqk80DL4FrBjzZcYqbKs/SpsPv6MVX6BLICabPfI=.ed25519",
                  "The Weekley": "@iVPi/B73hJSpsUB8XbSnlxe3NembPXLjOfIexlYdgJA=.ed25519"]

    var all: [String: Identity] {
        return self.pubs.merging(self.people) { (current, _) in current }
    }
}

struct VerseIdentities {

    let pubs = ["testpub_js": "@SwPgz6L0SN78lmv3GDaa2dIAJ0j91GiRI05G9H1w0ys=.ed25519",
                "testpub_go": "@BEN6tlUwG8UbiAjK/dtmkrLFNworYkRJBZuxNbc2x0I=.ed25519"]

    let people = ["christian":      "@uZsQmjnC5fjZCrRfH8ADSx9Kbx64Na5wvYoESS3VFqw=.ed25519",
                  "christoph_ios":  "@6MmU/s6qlBb6kaxoGxQiCDubMdOoDOoKhqfF53zFVFo=.ed25519",
                  "christoph_sim":  "@WacATfmBwkyi1DcTduD3/sXIGHvrizWJvGXIIM4qMTY=.ed25519",
                  "henry":          "@VG+jsSyURWMocK+oMb8j9wzHV2rLfxxdEZcTJ+CxsOc=.ed25519",
                  "rabble":         "@1yHRAWUAut2Y6qCkVK0bxcvFy1NgrEujv9t2sOUjcQk=.ed25519",
                  "rabble-patch":   "@SwPgz6L0SN78lmv3GDaa2dIAJ0j91GiRI05G9H1w0ys=.ed25519",
                  "tom":            "@xCLF6kP1NMcVGDSkIcbwB9ZdrX5S/yhE7CjFVdtE8LU=.ed25519"]

    var all: [String: Identity] {
        return self.pubs.merging(self.people) { (current, _) in current }
    }
}

struct TestNetIdentities {
    
    let pubs = ["integrationpub1": "@AJ/1x0/G78jRNriBqgV+ucDe5IPgpEap/sV2PPs61LI=.ed25519"]
    
    var all: [String: Identity] {
        return self.pubs
    }
}

struct PlanetaryIdentities {

    let pubs = ["testpub_go1": "@SVigTE9FieHqbHymVX080tR8DCpk5v5LmX4mnxKd7M0=.ggfeed-v1",
                "testpub_go2": "@pSF/XwM1choNE3sk60QO8jUk+a7n/6jJ5dJ/o9IeloE=.ggfeed-v1",
                "testpub_go3": "@R2COJoY/JwWUZMu0yv67kGDNCSBCXzvdL7dZ4sIhz/c=.ggfeed-v1",
                "testpub_go4": "@GotH+E4WwlWTdVDF9VmY2JOsuFfCavit5x+OyEz3HAQ=.ggfeed-v1",
                "testpub_go_testing1": "@T2zAqlShDWOCLJnleB3XMshoBFXZsLQmiIgK9m+g0To=.ggfeed-v1",
                "testpub_go_testing2": "@8shdLm9pVJQWnl1JymnljflcNZlCjHgh8/LGTWsMLVA=.ggfeed-v1"]
    
    let people = ["Planetary":          "@1TBkfmdEjgLnjucHWaluBR31mFmkLp8/v+BgqMu4+9U=.ed25519",
                  "Christian":          "@2l7hLH0QYOr1xePsdKvCH2TlLk8crOf7VJCAaNbia7A=.ggfeed-v1",
                  "henry":              "@u8DoI07mlGaqaqA29dcpMmIHoSxenHZpQUaZrU03WFM=.ggfeed-v1",
                  "Christoph.iPhone":   "@zlQFf3SnQaIB7ShDzqQlY2DaFRJn5Qs4yVyHXgVOBNA=.ggfeed-v1",
                  "Christoph.sim":      "@yykvlH6l2FGATJxDPr7PNzRROUsnweUudC+C9EF2e3s=.ggfeed-v1",
                  "Rabble":             "@FJuMvefQLjBGZLaZSTEpRQ/6UwhqcqgjKgvKaurPYuc=.ggfeed-v1",
                  "Tom":                "@/AoGtAfqdS77/AIOBhI5XwYgRDT8QInuKmofhvI5bgQ=.ggfeed-v1",
                  "Zef":                "@GnOAKf5u8ynUAENjdibTJ80oIV3csrgjEW5TYMVLjFA=.ggfeed-v1"]

    var all: [String: Identity] {
        return self.pubs.merging(self.people) { (current, _) in current }
    }
}

extension Identities {

    static let ssb = SSBIdentities()
    static let verse = VerseIdentities()
    static let planetary = PlanetaryIdentities()
    static let testNet = TestNetIdentities()

    static func `for`(_ network: NetworkKey) -> [Identity] {
        if network == NetworkKey.ssb    { return Array(Identities.ssb.all.values) }
        if network == NetworkKey.verse  { return Array(Identities.verse.all.values) }
        if network == NetworkKey.planetary  { return Array(Identities.planetary.all.values) }
        if network == NetworkKey.integrationTests { return Array(Identities.testNet.all.values)}
        return[]
    }

    /// Returns a copy of the array without Verse or Planetary pubs included.
    func withoutPubs() -> Identities {
        var set = Set(self)
        for pub in Identities.verse.pubs.values { set.remove(pub) }
        for pub in Identities.planetary.pubs.values { set.remove(pub) }
        return Array(set)
    }
}
