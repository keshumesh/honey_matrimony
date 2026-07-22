class AddVoicePromptColumnsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :voice_prompt_url, :string
    add_column :users, :voice_prompt_duration, :integer, default: 0
    add_column :users, :willing_to_relocate, :boolean, default: true
  end
end
