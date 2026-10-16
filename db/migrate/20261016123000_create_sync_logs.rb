class CreateSyncLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_logs do |t|
      t.references :sync_run, null: false, foreign_key: true
      t.string :log_type, null: false
      t.string :status, null: false
      t.string :action
      t.integer :page
      t.integer :attempt
      t.string :record_type
      t.string :external_id
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.string :error_class
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :sync_logs, [ :sync_run_id, :status ]
    add_index :sync_logs, [ :sync_run_id, :page ]
    add_index :sync_logs, [ :record_type, :external_id ]
  end
end
