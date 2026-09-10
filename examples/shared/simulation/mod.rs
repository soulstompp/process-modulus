//! A bench that produces histories, and two instruments that watch it.
//!
//! ⭐⭐⭐ THE ONE IDEA. A history is the whole truth of a run: every order, its size, how long
//! it waited and what became of it. **A filing is not a history.** It is what one instrument
//! could record, folded over a window. This module builds the history on NeXosim and then
//! applies instruments to it, so that the difference between what happened and what can be
//! filed is a value in a variable rather than a worry in a paragraph.
//!
//! ⛔ THE MAP GOES ONE WAY AND WILL NOT COME BACK. Many histories produce the same log, so
//! the log does not name a history, it names a **set** of them. That set is why an instrument
//! reports a range and not a number, and it is why `narrowingKind = instrument` exists in the
//! schema: no amount of re-running narrows a fibre, because the width was created by the
//! projection and not by the world.
//!
//! ⭐ WHAT IS ONLY TRUE INSIDE THE BENCH. In the wild you hold the log and the history is gone.
//! Here you hold both at once, which is the only place the width of that set can be measured
//! rather than assumed. Measuring it once is what licenses quoting it later.

// ⛔ EACH EXAMPLE COMPILES THIS WHOLE MODULE AND USES PART OF IT, so a helper that only
//    `resolution` needs is dead code when `generation` is built and the other way round. The
//    alternative is splitting the generator per consumer, which would put the physics in two
//    places and is exactly how two benches come to disagree.
#![allow(dead_code)]

pub mod event;
pub mod filing;
pub mod instrument;
pub mod layer;
pub mod pipeline;
pub mod quantum;
pub mod window;
