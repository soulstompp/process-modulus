//! A PostgreSQL server of the tests' own, made for one test and gone when it ends.
//!
//! It is made from the PostgreSQL that `PG_CONFIG` names, or else from the `pg_config` on the
//! path: `initdb` into a fresh directory under the system's temporary directory, listening on
//! localhost alone, on a port the system hands out. The tests reach it only over a connection,
//! with that installation's `psql`. It loads the schema and the ingest from the repository root,
//! as the pages say. Then, when `PROCESS_MODULUS_SERVER_SETUP` names an SQL file, it runs that
//! file on the loaded database, so a server's owner can give it what they want it to have
//! without this repository naming any of it. When the test ends, the server is stopped and its
//! directory removed.

#![allow(dead_code)]

use std::env;
use std::fs;
use std::io::Write;
use std::net::TcpListener;
use std::path::{Path, PathBuf};
use std::process::{Command, Output, Stdio};
use std::time::{SystemTime, UNIX_EPOCH};

/// The database the documents are loaded into.
pub const DATABASE: &str = "process_modulus";

/// What separates columns and rows in what `query` returns: neither occurs in the documents.
pub const COLUMN: char = '\u{1f}';
pub const ROW: char = '\u{1e}';

pub struct Server {
    bin: PathBuf,
    dir: PathBuf,
    port: u16,
}

impl Server {
    /// Make the server, start it, and load the documents into it.
    pub fn start() -> Result<Server, String> {
        let bin = bindir()?;
        let stamp = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |d| d.as_nanos());
        let dir = env::temp_dir().join(format!("process-modulus-{}-{stamp}", std::process::id()));
        let port = TcpListener::bind("127.0.0.1:0")
            .and_then(|l| l.local_addr())
            .map_err(|e| format!("no free port on localhost: {e}"))?
            .port();
        let server = Server { bin, dir, port };

        let data = server.dir.join("data");
        server.run(Command::new(server.bin.join("initdb")).arg("-D").arg(&data).args(["-A", "trust", "--no-sync"]))?;
        let mut conf = fs::read_to_string(data.join("postgresql.conf")).map_err(|e| e.to_string())?;
        conf.push_str(&format!(
            "\nport = {port}\nlisten_addresses = 'localhost'\nunix_socket_directories = ''\njit = off\n"
        ));
        fs::write(data.join("postgresql.conf"), conf).map_err(|e| e.to_string())?;
        server
            .run(
                Command::new(server.bin.join("pg_ctl"))
                    .arg("-D")
                    .arg(&data)
                    .arg("-l")
                    .arg(server.dir.join("server.log"))
                    .args(["-w", "start"]),
            )
            .map_err(|e| format!("{e}\n{}", server.log()))?;

        server.run(server.psql("postgres").args(["-c", &format!("CREATE DATABASE {DATABASE}")]))?;
        server.run(server.psql(DATABASE).args(["-f", "assets/ddl/schema.ddl", "-f", "assets/sql/ingest.sql"]))?;
        if let Some(setup) = env::var_os("PROCESS_MODULUS_SERVER_SETUP") {
            server.run(server.psql(DATABASE).arg("-f").arg(setup))?;
        }
        Ok(server)
    }

    /// `psql` on `database`, from the repository root, stopping at the first error.
    pub fn psql(&self, database: &str) -> Command {
        let mut psql = Command::new(self.bin.join("psql"));
        psql.current_dir(env!("CARGO_MANIFEST_DIR"))
            .args(["-X", "-q", "-v", "ON_ERROR_STOP=1", "-h", "localhost"])
            .args(["-p", &self.port.to_string(), "-d", database]);
        psql
    }

    /// Run the SQL file at `path`, relative to the repository root, and return what it printed.
    pub fn run_file(&self, path: &Path) -> Result<String, String> {
        self.run(self.psql(DATABASE).arg("-f").arg(path))
    }

    /// The rows `sql` returns, each a list of its columns, a NULL as an empty string. The
    /// statement goes to `psql` on its standard input, since a composed one is longer than an
    /// argument may be.
    pub fn query(&self, sql: &str) -> Result<Vec<Vec<String>>, String> {
        let mut psql = self.psql(DATABASE);
        psql.args(["-A", "-t", "-F", &COLUMN.to_string(), "-R", &ROW.to_string(), "-f", "-"])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped());
        let mut child = psql.spawn().map_err(|e| format!("psql could not start: {e}"))?;
        let mut stdin = child.stdin.take().ok_or("psql took no input")?;
        stdin.write_all(sql.as_bytes()).map_err(|e| format!("psql took no input: {e}"))?;
        drop(stdin);
        let Output { status, stdout, stderr } = child.wait_with_output().map_err(|e| e.to_string())?;
        if !status.success() {
            return Err(format!("psql failed: {}", String::from_utf8_lossy(&stderr).trim_end()));
        }
        let out = String::from_utf8_lossy(&stdout);
        Ok(out
            .trim_end_matches('\n')
            .split(ROW)
            .filter(|row| !row.is_empty())
            .map(|row| row.split(COLUMN).map(str::to_string).collect())
            .collect())
    }

    /// The server's version, and the libraries every session on the documents' database loads.
    pub fn describe(&self) -> Result<String, String> {
        let rows = self.query("SELECT version(), current_setting('session_preload_libraries')")?;
        let row = rows.first().ok_or("the server described nothing")?;
        let preload = if row[1].is_empty() { "none" } else { &row[1] };
        Ok(format!("{}\nloaded by every session: {preload}", row[0]))
    }

    fn run(&self, command: &mut Command) -> Result<String, String> {
        let shown = format!("{command:?}");
        let Output { status, stdout, stderr } =
            command.output().map_err(|e| format!("{shown} could not start: {e}"))?;
        if status.success() {
            Ok(String::from_utf8_lossy(&stdout).into_owned())
        } else {
            Err(format!("{shown} failed: {}", String::from_utf8_lossy(&stderr).trim_end()))
        }
    }

    fn log(&self) -> String {
        fs::read_to_string(self.dir.join("server.log")).unwrap_or_default()
    }
}

impl Drop for Server {
    fn drop(&mut self) {
        let data = self.dir.join("data");
        if data.join("postmaster.pid").exists() {
            let _ = Command::new(self.bin.join("pg_ctl")).arg("-D").arg(&data).args(["-m", "fast", "-w", "stop"]).output();
        }
        let _ = fs::remove_dir_all(&self.dir);
    }
}

/// The directory holding the PostgreSQL programs: `pg_config --bindir`, from `PG_CONFIG` or the
/// path.
fn bindir() -> Result<PathBuf, String> {
    let pg_config = env::var_os("PG_CONFIG").unwrap_or_else(|| "pg_config".into());
    let out = Command::new(&pg_config).arg("--bindir").output().map_err(|e| {
        format!(
            "these tests start a PostgreSQL server of their own, and found no `pg_config` to make it \
             from ({}: {e}). Set PG_CONFIG to the pg_config of the PostgreSQL to use.",
            pg_config.to_string_lossy()
        )
    })?;
    if !out.status.success() {
        return Err(format!("{} --bindir failed", pg_config.to_string_lossy()));
    }
    Ok(PathBuf::from(String::from_utf8_lossy(&out.stdout).trim()))
}
