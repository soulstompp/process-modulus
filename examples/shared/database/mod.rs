//! The one way a program here opens its database.
//!
//! Every session runs with Postgres's just-in-time compiler off. The statements these programs
//! run compose the relation tree into single plans, and past `jit_above_cost` Postgres compiles
//! such a plan to machine code before executing it, which for a plan this deep costs far more
//! than the execution does. The setting decides when a plan is compiled, never what it returns.

use std::str::FromStr;

use sqlx::postgres::{PgConnectOptions, PgPool};

/// A pool on `url` whose every session runs with `jit = off`.
pub async fn connect(url: &str) -> Result<PgPool, sqlx::Error> {
    let options = PgConnectOptions::from_str(url)?.options([("jit", "off")]);
    PgPool::connect_with(options).await
}
