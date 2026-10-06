//! A bench that produces histories, and two instruments that watch it.
//!
//! A history is the whole of a run: every order, its size, how long it waited and what became of
//! it. A filing is not a history. It is what one instrument could record, totalled over a window.
//! This module builds the history on NeXosim and then applies instruments to it, so the difference
//! between what happened and what can be filed is a value in a variable.
//!
//! Many histories produce the same log, so a log does not name one history but a set of them.
//! That set is why an instrument reports a range and not a number, and why
//! `narrowingKind = instrument` exists in the schema: running again narrows nothing, because the
//! width comes from what the instrument records and not from the world.
//!
//! In the wild you hold the log and the history is gone. Inside the bench you hold both, which is
//! the one place the width of that set can be measured rather than assumed, and measuring it once
//! is what allows quoting it later.

// Each example compiles this whole module and uses part of it, so a helper only `resolution`
// needs is dead code when `generation` is built, and the other way round. One generator serves
// every example, so the physics is written in one place.
#![allow(dead_code)]

pub mod event;
pub mod filing;
pub mod instrument;
pub mod layer;
pub mod pipeline;
pub mod quantum;
pub mod window;
