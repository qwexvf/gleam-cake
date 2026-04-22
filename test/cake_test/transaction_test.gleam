import birdie
import cake/insert as i
import cake/select as s
import gleam/dynamic/decode
import pprint.{format as to_string}
import test_helper/maria_test_helper
import test_helper/mysql_test_helper
import test_helper/postgres_test_helper
import test_helper/sqlite_test_helper
import test_support/adapter/maria
import test_support/adapter/mysql
import test_support/adapter/postgres
import test_support/adapter/sqlite

fn insert_txn_cat_query(name: String) {
  [[name |> i.string, i.float(0.0), i.int(0)] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name", "rating", "age"])
  |> i.to_query
}

fn insert_txn_cat_maria_mysql_query(name: String) {
  [[name |> i.string, i.float(0.0), i.int(0)] |> i.row]
  |> i.from_values(table_name: "cats", columns: ["name", "rating", "age"])
  |> i.no_returning
  |> i.to_query
}

fn select_cat_names_query() {
  s.new()
  |> s.from_table("cats")
  |> s.selects([s.col("name")])
  |> s.order_by_asc("name")
  |> s.to_query
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Commit tests                                                             │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn transaction_commit_test() {
  let pgo =
    postgres_test_helper.with_setup_connection(fn(conn) {
      let assert Ok(_) =
        postgres.with_transaction(conn, fn(txn) {
          insert_txn_cat_query("TxCat")
          |> postgres.run_write_query(decode.dynamic, txn)
        })
      select_cat_names_query()
      |> postgres.run_read_query(decode.dynamic, conn)
    })

  let lit =
    sqlite_test_helper.with_setup_connection(fn(conn) {
      let assert Ok(_) =
        sqlite.with_transaction(conn, fn(txn) {
          insert_txn_cat_query("TxCat")
          |> sqlite.run_write_query(decode.dynamic, txn)
        })
      select_cat_names_query()
      |> sqlite.run_read_query(decode.dynamic, conn)
    })

  let mdb =
    maria_test_helper.with_setup_connection(fn(conn) {
      let assert Ok(_) =
        maria.with_transaction(conn, fn(txn) {
          insert_txn_cat_maria_mysql_query("TxCat")
          |> maria.run_write_query(decode.dynamic, txn)
        })
      select_cat_names_query()
      |> maria.run_read_query(decode.dynamic, conn)
    })

  let myq =
    mysql_test_helper.with_setup_connection(fn(conn) {
      let assert Ok(_) =
        mysql.with_transaction(conn, fn(txn) {
          insert_txn_cat_maria_mysql_query("TxCat")
          |> mysql.run_write_query(decode.dynamic, txn)
        })
      select_cat_names_query()
      |> mysql.run_read_query(decode.dynamic, conn)
    })

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("transaction_commit_test")
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │  Rollback tests                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn transaction_rollback_test() {
  let pgo =
    postgres_test_helper.with_setup_connection(fn(conn) {
      let _ =
        postgres.with_transaction(conn, fn(txn) {
          let assert Ok(_) =
            insert_txn_cat_query("RollbackCat")
            |> postgres.run_write_query(decode.dynamic, txn)
          Error(Nil)
        })
      select_cat_names_query()
      |> postgres.run_read_query(decode.dynamic, conn)
    })

  let lit =
    sqlite_test_helper.with_setup_connection(fn(conn) {
      let _ =
        sqlite.with_transaction(conn, fn(txn) {
          let assert Ok(_) =
            insert_txn_cat_query("RollbackCat")
            |> sqlite.run_write_query(decode.dynamic, txn)
          Error(Nil)
        })
      select_cat_names_query()
      |> sqlite.run_read_query(decode.dynamic, conn)
    })

  let mdb =
    maria_test_helper.with_setup_connection(fn(conn) {
      let _ =
        maria.with_transaction(conn, fn(txn) {
          let assert Ok(_) =
            insert_txn_cat_maria_mysql_query("RollbackCat")
            |> maria.run_write_query(decode.dynamic, txn)
          Error("rollback")
        })
      select_cat_names_query()
      |> maria.run_read_query(decode.dynamic, conn)
    })

  let myq =
    mysql_test_helper.with_setup_connection(fn(conn) {
      let _ =
        mysql.with_transaction(conn, fn(txn) {
          let assert Ok(_) =
            insert_txn_cat_maria_mysql_query("RollbackCat")
            |> mysql.run_write_query(decode.dynamic, txn)
          Error("rollback")
        })
      select_cat_names_query()
      |> mysql.run_read_query(decode.dynamic, conn)
    })

  #(pgo, lit, mdb, myq)
  |> to_string
  |> birdie.snap("transaction_rollback_test")
}
