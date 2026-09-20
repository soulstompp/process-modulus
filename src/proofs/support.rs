// What every block on the proofs page includes, and nothing else compiles.
//
// Each block pulls this file in with `include!`, so it is compiled once per block and never into
// the library: nothing declares it as a module and no target discovers it. It reads documents
// with this crate's own types and hands back the figures they state. Apart from the tolerance
// `close` compares within, it does no arithmetic: every subtraction, sum, bound and magnitude a
// proof relies on is written in the block that relies on it, where a reader can see it.

use std::fs;

use process_modulus::asrt::{
    CompositionType, EliminationAgainstType, FusionType, PartType, StatedEliminationsTypeContent,
};
use process_modulus::pm::{
    ClaimAbsenceReasonType, ClaimType, DivisibilityTypeContent, FitType, HolderKindType,
    IdentityType, LayerType, ProcessModulusElementType, StatedClaimType, StatedCouplingsTypeContent,
    StatedDivisibilityType, StatedEliminatedQuantityType, StatedFactorType, StatedFitType,
    StatedHolderType, StatedLumpyQuantumType, StatedMagnitudeType, StatedRemainderType,
    StatedShareType, StatedSummedQuantityType, StatedTimeSlackType,
};
use xsd_parser_types::quick_xml::{DeserializeSync, SliceReader};

// A three-point claim, as `(low, mostLikely, high)`.
type Triple = (f64, f64, f64);

// A document under `assets/`, read as text.
fn read(path: &str) -> String {
    let full = format!("{}/assets/{path}", env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(&full).unwrap_or_else(|e| panic!("{full}: {e}"))
}

// A filing, from its path under `assets/`: `filing("corpus/refutation.xml")`.
fn filing(path: &str) -> ProcessModulusElementType {
    let xml = read(path);
    ProcessModulusElementType::deserialize(&mut SliceReader::new(&xml))
        .unwrap_or_else(|e| panic!("{path}: {e}"))
}

// A composition, from its path under `assets/`. Its own stack is `.process_modulus`.
fn composition(path: &str) -> CompositionType {
    let xml = read(path);
    CompositionType::deserialize(&mut SliceReader::new(&xml))
        .unwrap_or_else(|e| panic!("{path}: {e}"))
}

// One layer of a filing's stack, by name.
fn layer<'a>(doc: &'a ProcessModulusElementType, name: &str) -> &'a LayerType {
    doc.stack
        .layer
        .iter()
        .find(|l| l.name == name)
        .unwrap_or_else(|| panic!("no layer `{name}`"))
}

// What a figure's wrapper files. Every position an identity may compute has a wrapper of its own,
// so the generated types are several of one shape: a claim, a typed absence, or a derivation
// naming the identity that computes it. `StatedClaimType` has no derivation arm.
trait Filed {
    fn stated(&self) -> Option<&ClaimType>;
    fn absent(&self) -> Option<&ClaimAbsenceReasonType>;
    fn derived(&self) -> Option<&IdentityType>;
}

macro_rules! filed {
    ($($t:ident),*) => {$(
        impl Filed for $t {
            fn stated(&self) -> Option<&ClaimType> {
                match self {
                    $t::Claim(c) => Some(c),
                    _ => None,
                }
            }
            fn absent(&self) -> Option<&ClaimAbsenceReasonType> {
                match self {
                    $t::Absent(a) => Some(&a.reason),
                    _ => None,
                }
            }
            fn derived(&self) -> Option<&IdentityType> {
                match self {
                    $t::Derivation(d) => Some(&d.identity),
                    _ => None,
                }
            }
        }
    )*};
}

filed!(
    StatedSummedQuantityType,
    StatedMagnitudeType,
    StatedTimeSlackType,
    StatedShareType,
    StatedFactorType,
    StatedEliminatedQuantityType
);

impl Filed for StatedClaimType {
    fn stated(&self) -> Option<&ClaimType> {
        match self {
            StatedClaimType::Claim(c) => Some(c),
            StatedClaimType::Absent(_) => None,
        }
    }
    fn absent(&self) -> Option<&ClaimAbsenceReasonType> {
        match self {
            StatedClaimType::Claim(_) => None,
            StatedClaimType::Absent(a) => Some(&a.reason),
        }
    }
    fn derived(&self) -> Option<&IdentityType> {
        None
    }
}

// A claim's three points, or `None` where the filing states a typed absence or a derivation instead.
fn claim(s: &impl Filed) -> Option<Triple> {
    s.stated().map(|c| (c.low, c.most_likely, c.high))
}

// Why a claim is absent, or `None` where it is stated or derived.
fn absence(s: &impl Filed) -> Option<&ClaimAbsenceReasonType> {
    s.absent()
}

// The identity that computes a figure filed as a derivation, or `None` where it is stated or absent.
fn derivation(s: &impl Filed) -> Option<&IdentityType> {
    s.derived()
}

// A claim's unit, or `None` where it is absent or derived.
fn unit(s: &impl Filed) -> Option<&str> {
    s.stated().map(|c| c.unit.as_str())
}

// The layer's demand, `d`.
fn demand(l: &LayerType) -> Triple {
    claim(&l.demand.amount).unwrap_or_else(|| panic!("`{}` states no demand", l.name))
}

// The layer's nameplate, `n`.
fn nameplate(l: &LayerType) -> Triple {
    claim(&l.supply.nameplate.amount).unwrap_or_else(|| panic!("`{}` states no nameplate", l.name))
}

// The layer's draw, what the supply actually delivered.
fn draw(l: &LayerType) -> Triple {
    claim(&l.supply.jagged.draw).unwrap_or_else(|| panic!("`{}` states no draw", l.name))
}

// The duty cycle a nameplate files, with its unit, or `None` where it files none.
fn window(l: &LayerType) -> Option<(Triple, &str)> {
    let StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        return None;
    };
    d.content.iter().find_map(|c| match c {
        DivisibilityTypeContent::Window(StatedLumpyQuantumType::Quantum(w)) => {
            Some((claim(&w.size)?, unit(&w.size)?))
        }
        _ => None,
    })
}

// The quantum a lumpy supply arrives in, or `None` where the supply is not stated lumpy.
fn quantum(l: &LayerType) -> Option<Triple> {
    let StatedDivisibilityType::Divisibility(d) = &l.supply.nameplate.divisibility else {
        return None;
    };
    d.content.iter().find_map(|c| match c {
        DivisibilityTypeContent::Lumpy(q) => claim(&q.size),
        _ => None,
    })
}

// The fusion that composes a composition's layer, by that layer's name.
fn fusion<'a>(c: &'a CompositionType, name: &str) -> &'a FusionType {
    c.fusion
        .iter()
        .find(|f| f.name == name)
        .unwrap_or_else(|| panic!("no fusion composes `{name}`"))
}

// One part of a fusion, by the name of the layer it takes.
fn part<'a>(f: &'a FusionType, layer: &str) -> &'a PartType {
    f.part
        .iter()
        .find(|p| p.layer.filing.id == layer)
        .unwrap_or_else(|| panic!("`{}` has no part `{layer}`", f.name))
}

// A part's conversion factor, or `None` where it files none, a typed absence or a derivation.
fn factor(p: &PartType) -> Option<Triple> {
    p.factor.as_ref().and_then(|f| claim(f))
}

// The elimination a fusion files against one quantity, or `None` where it files none.
fn elimination(f: &FusionType, against: EliminationAgainstType) -> Option<Triple> {
    f.eliminations.content.iter().find_map(|e| match e {
        StatedEliminationsTypeContent::Elimination(e) if e.against == against => claim(&e.quantity),
        _ => None,
    })
}

// The strength a stack files for its coupling between two layers.
fn coupling(doc: &ProcessModulusElementType, from: &str, to: &str) -> Triple {
    doc.stack
        .couplings
        .content
        .iter()
        .find_map(|c| match c {
            StatedCouplingsTypeContent::Coupling(k) if k.from == from && k.to == to => {
                claim(&k.strength)
            }
            _ => None,
        })
        .unwrap_or_else(|| panic!("no sized coupling `{from}` -> `{to}`"))
}

// The fit the filing states for its remainder, or `None` where it states none or files it as a
// derivation.
fn sign(l: &LayerType) -> Option<&FitType> {
    match &l.remainder {
        StatedRemainderType::Remainder(r) => match &r.sign {
            StatedFitType::Fit(f) => Some(f),
            StatedFitType::Derivation(_) | StatedFitType::Absent(_) => None,
        },
        StatedRemainderType::Absent(_) => None,
    }
}

// The remainder's stated `quantity`, or `None` where it is absent or a derivation.
fn quantity(l: &LayerType) -> Option<Triple> {
    match &l.remainder {
        StatedRemainderType::Remainder(r) => claim(&r.quantity),
        StatedRemainderType::Absent(_) => None,
    }
}

// Every holder's share, in filing order, `None` for a share filed as a typed absence.
fn shares(l: &LayerType) -> Vec<Option<Triple>> {
    match &l.remainder {
        StatedRemainderType::Remainder(r) => r
            .holder
            .iter()
            .filter_map(|h| match h {
                StatedHolderType::Holder(h) => Some(claim(&h.share)),
                StatedHolderType::Absent(_) => None,
            })
            .collect(),
        StatedRemainderType::Absent(_) => Vec::new(),
    }
}

// Every holder with its kind and its share, in filing order, the share `None` where it is absent.
fn holders(l: &LayerType) -> Vec<(&HolderKindType, Option<Triple>)> {
    match &l.remainder {
        StatedRemainderType::Remainder(r) => r
            .holder
            .iter()
            .filter_map(|h| match h {
                StatedHolderType::Holder(h) => Some((&h.kind, claim(&h.share))),
                StatedHolderType::Absent(_) => None,
            })
            .collect(),
        StatedRemainderType::Absent(_) => Vec::new(),
    }
}

// Two figures agree to within 1e-9, the one tolerance `assets/sqlc/` compares within wherever it uses one.
fn close(a: f64, b: f64) -> bool {
    (a - b).abs() < 1e-9
}

// Two three-point claims agree at all three points.
fn close3(a: Triple, b: Triple) -> bool {
    close(a.0, b.0) && close(a.1, b.1) && close(a.2, b.2)
}
