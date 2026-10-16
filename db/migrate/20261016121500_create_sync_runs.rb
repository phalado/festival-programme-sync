class CreateSyncRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_runs do |t|
      t.string :status, null: false, default: "running"
      t.integer :total_pages
      t.integer :completed_pages, array: true, null: false, default: []
      t.datetime :finished_at
      t.text :error_message

      t.timestamps
    end

    add_index :sync_runs,
      :status,
      unique: true,
      where: "status = 'running'",
      name: "index_sync_runs_on_running_status"
  end
end
