import Foundation

/// Role: Felt. Simulator-only room pack on the pie. Device never seeds. Guard is nbl.demo.v1.
enum FeltSeed {
    static func felt() -> Felt {
        let names = ["Marlo", "Vesper", "Nix", "Calico"]
        let pack = BoothPack(title: "Sawdust room", names: names)
        var open: UInt64 = 0
        let slices = names.enumerated().map { index, name in
            open |= PieMask.bit(index)
            return Slice(name: name, bit: index)
        }
        return Felt(
            slices: slices,
            packs: [pack],
            openMask: open,
            nailedMask: 0,
            nights: [],
            hapticsOn: true,
            onboardingComplete: true
        )
    }

    static func nighted() -> Felt {
        var felt = felt()
        felt.nailedMask = PieMask.bit(0)
        let first = felt.slices[0]
        felt.nights = [
            Night(
                key: NightKey(rawValue: 20260502),
                lands: [Land(sliceID: first.id, name: first.name, bit: first.bit)]
            )
        ]
        return felt
    }
}
